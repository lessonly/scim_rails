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
      member_ids.each do |id|
        user = @company.public_send(ScimRails.config.scim_users_scope).find(id)
        group.users << user
      end

      json_scim_group_response(object: group)
    end

    # TODO: complete method
    def patch_update

    end

    private

    def put_error_check
      members = params["members"]

      raise ScimRails::ExceptionHandler::InvalidPutMembers unless (members.is_a?(Array) && array_of_hashes?(members))

      member_ids = members.map{ |member| member["value"] }

      member_ids.each do |id|
        @company.public_send(ScimRails.config.scim_users_scope).find(id)
      end
        
      return if put_active_param.nil?

      case put_active_param
      when true, "true", 1
        
      when false, "false", 0
        
      else
        raise ScimRails::ExceptionHandler::InvalidActiveParam
      end
    end

    def array_of_hashes?(array)
      array.each do |element|
        return false unless element.is_a?(Hash)
      end

      return true
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
        nil
      when Array
        at_path.each_with_index do |value, index|
          found_path = path_for(attribute, object, [*path, index])
          return found_path if found_path
        end
        nil
      end
    end

  end
end
