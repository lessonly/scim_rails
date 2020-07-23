module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

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

      ScimRails.config.after_scim_response.call(groups, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: groups, counts: counts)
    end

    def create
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      group_attributes = permitted_group_params(params)

      if ScimRails.config.scim_group_prevent_update_on_create
        group = @company.public_send(ScimRails.config.scim_groups_scope).create!(group_attributes.except(:members))
      else
        username_key = ScimRails.config.queryable_group_attributes[:userName]
        find_by_username = {}
        find_by_username[username_key] = group_attributes[username_key]
        group = @company
          .public_send(ScimRails.config.scim_groups_scope)
          .find_or_create_by(find_by_username)
        group.update!(group_attributes.except(:members))
      end

      update_group_status(group) unless put_active_param.nil?

      ScimRails.config.after_scim_response.call(group, "CREATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: group, status: :created)
    end

    def show
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])

      ScimRails.config.after_scim_response.call(group, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: group)
    end

    def put_update
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])

      put_error_check

      group_attributes = permitted_group_params(params)
      group.update!(group_attributes.except(:members))

      update_group_status(group) unless put_active_param.nil?

      member_ids = params["members"]&.map{ |member| member["value"] }

      group.public_send(ScimRails.config.scim_group_member_scope).clear
      add_members(group, member_ids)

      ScimRails.config.after_scim_response.call(group, "UPDATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: group)
    end

    def patch_update
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])

      group.update!(ScimRails.config.custom_group_attributes)

      if params.key?("members")
        one_login_member_patch(group, params["members"])
      else
        process_operations(group, params)
      end

      ScimRails.config.after_scim_response.call(group, "UPDATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: group)
    end

    def delete
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      group.update!(ScimRails.config.custom_group_attributes)

      group.destroy

      ScimRails.config.after_scim_response.call(group, "DELETED") unless ScimRails.config.after_scim_response.nil?

      json_scim_group_response(object: nil, status: :no_content)
    end

    private

    def members_to_added_ids(members)
      members.map{ |member| member["value"] unless member.key?("operation") }.compact
    end

    def members_to_deleted_ids(members)
      members.map{ |member| member["value"] if (member.key?("operation") && member["operation"] == "delete") }.compact
    end

    def one_login_member_patch(group, members)
      member_error_check(members)

      ids_to_be_added = members_to_added_ids(members)
      ids_to_be_deleted = members_to_deleted_ids(members)

      add_members(group, ids_to_be_added) unless ids_to_be_added.empty?
      remove_members(group, ids_to_be_deleted) unless ids_to_be_deleted.empty?
    end

    def process_operations(group, params)
      params["Operations"].each do |operation|
        case operation["op"].downcase
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
    end

    def member_error_check(members)
      raise ScimRails::ExceptionHandler::InvalidMembers unless (members.is_a?(Array) && array_of_hashes?(members))

      member_ids = members.map{ |member| member["value"] }

      @company.public_send(ScimRails.config.scim_users_scope).find(member_ids)
    end

    def add_members(group, member_ids)
      new_member_ids = member_ids - group.public_send(ScimRails.config.scim_group_member_scope).pluck(:id)
      new_members = @company.public_send(ScimRails.config.scim_users_scope).find(new_member_ids)
      
      group.public_send(ScimRails.config.scim_group_member_scope) << new_members if new_members.present?
    end

    def remove_members(group, member_ids)
      target_members = group.public_send(ScimRails.config.scim_group_member_scope).find(member_ids)

      group.public_send(ScimRails.config.scim_group_member_scope).destroy(target_members)
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

    def patch_replace_members(group, operation)
      member_error_check(operation["value"])

      group.public_send(ScimRails.config.scim_group_member_scope).clear

      member_ids = operation["value"].map{ |member| member["value"] }
      add_members(group, member_ids)
    end

    def patch_replace_attributes(group, operation)
      path_params = extract_path_params(operation)

      group_attributes = permitted_group_params(path_params || operation["value"])

      active_param = extract_active_param(operation, path_params)
      status = patch_group_status(active_param)

      group.update!(group_attributes.compact)

      return if status.nil?
      provision_method = status ? ScimRails.config.group_reprovision_method : ScimRails.config.group_deprovision_method
      group.public_send(provision_method)
    end

    def patch_replace(group, operation)
      if operation["path"] == "members"
        patch_replace_members(group, operation)
      else
        patch_replace_attributes(group, operation)
      end
    end

    def patch_add(group, operation)
      raise ScimRails::ExceptionHandler::BadPatchPath unless ["members", nil].include?(operation["path"])

      member_error_check(operation["value"])

      member_ids = operation["value"].map{ |member| member["value"] }

      add_members(group, member_ids)
    end

    def patch_remove(group, operation)
      path_string = operation["path"]

      if path_string == "members" && operation.key?("value")
        member_error_check(operation["value"])

        member_ids = operation["value"].map{ |member| member["value"] }

        remove_members(group, member_ids)
        return
        
      elsif path_string == "members"
        group.public_send(ScimRails.config.scim_group_member_scope).destroy_all
        return
      end

      pre_bracket_path = extract_from_before_square_brackets(path_string)
      filter = extract_from_inside_square_brackets(path_string)
      path_suffix = extract_from_after_square_brackets(path_string)

      raise ScimRails::ExceptionHandler::BadPatchPath unless (pre_bracket_path == "members" && path_suffix == "")

      query = filter_to_query(filter)

      members = @company
          .public_send(ScimRails.config.scim_users_scope)
          .where("#{query.query_elements[0]} #{query.operator} ?", query.parameter)

      members.each do |member|
        group.public_send(ScimRails.config.scim_group_member_scope).destroy(member.id)
      end
    end

    def filter_to_query(filter)
      args = filter.split(' ')

      raise ScimRails::ExceptionHandler::BadPatchPath unless args.length == 3

      # Convert the attribute from SCIM schema form to how it appears in the model so the query can be done
      # E.g. in the dummy app configuration, "value" as the attributes is converted like so: "value" -> :value -> :id -> "id"
      attribute = ScimRails.config.group_member_schema[args[0].to_sym].to_s

      operator = args[1]
      parameter = args[2]

      parsed_filter = [attribute, operator, parameter].join(' ')
      query = ScimRails::ScimQueryParser.new(parsed_filter)

      query
    end

    def array_of_hashes?(array)
      array.all? { |hash| hash.is_a?(ActionController::Parameters) }
    end

    def permitted_group_params(parameters)
      ScimRails.config.mutable_group_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = parameters.dig(*group_path_for(attribute))
      end.merge(ScimRails.config.custom_group_attributes)
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
