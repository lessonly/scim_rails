module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        groups = @company.public_send(ScimRails.config.scim_groups_scope)
                         .where("#{ScimRails.config.scim_groups_model.connection.quote_column_name(query.group_attribute)} #{query.operator} ?", query.parameter)
                         .order(ScimRails.config.scim_groups_list_order)
      else
        groups = @company.public_send(ScimRails.config.scim_groups_scope)
                         .order(ScimRails.config.scim_groups_list_order)
      end

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: groups.count
      )

      json_scim_group_response(object: groups, counts: counts)
    end

    def create
      group_attributes = permitted_group_params(params)

      if ScimRails.config.scim_group_prevent_update_on_create
        group = @company.public_send(ScimRails.config.scim_groups_scope).create!(group_attributes.except(:members))
      else
        username_key = ScimRails.config.queryable_group_attributes[:userName]
        find_by_username = Hash.new
        find_by_username[username_key] = group_attributes[username_key]
        group = @company
          .public_send(ScimRails.config.scim_groups_scope)
          .find_or_create_by(find_by_username)
        group.update!(group_attributes.except(:members))
      end

      update_group_status(group) unless put_active_param.nil?
      json_scim_group_response(object: group, status: :created)
    end

    def show
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      json_scim_group_response(object: group)
    end

    def put_update
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])

      put_error_check

      group_attributes = permitted_group_params(params)
      group.update!(group_attributes.except(:members))

      update_group_status(group) unless put_active_param.nil?

      member_ids = params["members"]&.map{ |member| member["value"] }

      group.users.clear
      add_members(group, member_ids)

      json_scim_group_response(object: group)
    end

    def patch_update
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])

      params["Operations"].each do |operation|
        case operation["op"]
        when "replace"
          patch_replace(group, operation)
        when "add"
          patch_add(group, operation)
        when "remove"
          patch_remove(group, operation)
        else
          raise ScimRails::ExceptionHandler::UnsupportedGroupPatchRequest
        end
      end

      json_scim_group_response(object: group)
    end

    private

    def member_error_check(members)
      raise ScimRails::ExceptionHandler::InvalidMembers unless (members.is_a?(Array) && array_of_hashes?(members))

      member_ids = members.map{ |member| member["value"] }

      member_ids.each do |id|
        @company.public_send(ScimRails.config.scim_users_scope).find(id)
      end
    end

    def add_members(group, member_ids)
      member_ids.each do |id|
        user = @company.public_send(ScimRails.config.scim_users_scope).find(id)
        if group.users.include? user

        else
          group.users << user
        end
      end
    end

    def put_error_check
      member_error_check(params["members"])
        
      return if put_active_param.nil?

      case put_active_param
      when true, "true", 1
        
      when false, "false", 0
        
      else
        raise ScimRails::ExceptionHandler::InvalidActiveParam
      end
    end

    def patch_replace(group, operation)
      case operation["path"]
      when "members"
        member_error_check(operation["value"])

        group.users.clear

        member_ids = operation["value"].map{ |member| member["value"] }
        add_members(group, member_ids)

      when nil
        group_attributes = permitted_group_params(operation["value"])

        active_param = operation.dig("value", "active")
        status = patch_group_status(active_param)

        group.update!(group_attributes.compact)

        return if status.nil?
        provision_method = status ? ScimRails.config.group_reprovision_method : ScimRails.config.group_deprovision_method
        group.public_send(provision_method)

      else
        raise ScimRails::ExceptionHandler::BadPatchPath
      end
    end

    def patch_add(group, operation)
      member_error_check(operation["value"])

      member_ids = operation["value"].map{ |member| member["value"] }

      add_members(group, member_ids)
    end

    def patch_remove(group, operation)
      path_string = operation["path"]

      if path_string == "members"
        group.users.delete_all
        return
      end

      # Everything before square brackets
      path = path_string.match(/([^\[]+)/).to_s

      # Everything within the square brackets
      filter = path_string.match(/(?<=\[).+?(?=\])/).to_s

      # Everything after the square brackets (this should be empty)
      extra = path_string.match(/(?<=\]).*/).to_s

      raise ScimRails::ExceptionHandler::BadPatchPath unless (path == "members" && extra == "")

      query = filter_to_query(filter)

      members = @company
          .public_send(ScimRails.config.scim_users_scope)
          .where("#{query.query_elements[0]} #{query.operator} ?", query.parameter)

      members.each do |member|
        group.users.find(member.id)
        group.users.delete(member)
      end
    end

    def filter_to_query(filter)
      args = filter.split(' ')

      raise ScimRails::ExceptionHandler::BadPatchPath unless args.length == 3

      # Convert the attribute from SCIM schema form to how it appears in the model so the query can be done
      attribute = ScimRails.config.group_member_schema[args[0].to_sym].to_s

      operator = args[1]
      parameter = args[2]

      parsed_filter = [attribute, operator, parameter].join(' ')
      query = ScimRails::ScimQueryParser.new(parsed_filter)

      query
    end

    def array_of_hashes?(array)
      array.all? { |hash| hash.is_a?(Hash) }
    end

    def permitted_group_params(parameters)
      ScimRails.config.mutable_group_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = parameters.dig(*group_path_for(attribute))
      end
    end

    def update_group_status(group)
      group.public_send(ScimRails.config.group_reprovision_method) if active?
      group.public_send(ScimRails.config.group_deprovision_method) unless active?
    end

    def group_path_for(attribute, object = ScimRails.config.mutable_group_attributes_schema, path = [])
      at_path = path.empty? ? object : object.dig(*path)
      return path if at_path == attribute

      case at_path
      when Hash
        at_path.each do |key, value|
          found_path = path_for(attribute, object, [*path, key])
          return found_path if found_path
        end
      when Array
        at_path.each_with_index do |value, index|
          found_path = path_for(attribute, object, [*path, index])
          return found_path if found_path
        end
      end
    end

    def patch_group_status(active_param)
      case active_param
      when true, "true", 1
        true
      when false, "false", 0
        false
      when nil
        nil
      else
        raise ScimRails::ExceptionHandler::InvalidActiveParam
      end
    end

  end
end
