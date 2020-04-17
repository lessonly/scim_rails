module ScimRails
  class ScimUsersController < ScimRails::ApplicationController
    def index
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        users = @company
          .public_send(ScimRails.config.scim_users_scope)
          .where(
            "#{ScimRails.config.scim_users_model.connection.quote_column_name(query.attribute)} #{query.operator} ?",
            query.parameter
          )
          .order(ScimRails.config.scim_users_list_order)
      else
        users = @company
          .public_send(ScimRails.config.scim_users_scope)
          .order(ScimRails.config.scim_users_list_order)
      end

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: users.count
      )

      json_scim_response(object: users, counts: counts)
    end

    def create
      if ScimRails.config.scim_user_prevent_update_on_create
        user = @company.public_send(ScimRails.config.scim_users_scope).create!(permitted_user_params)
      else
        username_key = ScimRails.config.queryable_user_attributes[:userName]
        find_by_username = Hash.new
        find_by_username[username_key] = permitted_user_params[username_key]
        user = @company
          .public_send(ScimRails.config.scim_users_scope)
          .find_or_create_by(find_by_username)
        user.update!(permitted_user_params)
      end
      update_status(user) unless put_active_param.nil?
      json_scim_response(object: user, status: :created)
    end

    def show
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      json_scim_response(object: user)
    end

    def put_update
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      update_status(user) unless put_active_param.nil?
      user.update!(permitted_user_params)
      json_scim_response(object: user)
    end

    def patch_update
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])

      params["Operations"].each do |operation|
        raise ScimRails::ExceptionHandler::UnsupportedPatchRequest if operation["op"] != "replace"

        changed_attributes = permitted_patch_params(operation["value"])

        user.update!(changed_attributes.compact)

        active_param = operation.dig("value", "active")
        active = patch_status(active_param)
        
        next if active.nil?
        user.public_send(ScimRails.config.user_reprovision_method) if active
        user.public_send(ScimRails.config.user_deprovision_method) unless active
      end

      json_scim_response(object: user)
    end

    private

    def permitted_patch_params(patch_params)
      ScimRails.config.mutable_user_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = patch_find_value_for(patch_params, attribute)
      end
    end

    def permitted_user_params
      ScimRails.config.mutable_user_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = find_value_for(attribute)
      end
    end

    def patch_find_value_for(patch_params, attribute)
      patch_params.dig(*path_for(attribute))
    end

    def find_value_for(attribute)
      params.dig(*path_for(attribute))
    end

    # `path_for` is a recursive method used to find the "path" for
    # `.dig` to take when looking for a given attribute in the
    # params.
    #
    # Example: `path_for(:name)` should return an array that looks
    # like [:names, 0, :givenName]. `.dig` can then use that path
    # against the params to translate the :name attribute to "John".

    def path_for(attribute, object = ScimRails.config.mutable_user_attributes_schema, path = [])
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

    # def put_update_status(user)
    #   user.public_send(ScimRails.config.user_reprovision_method) if put_active?
    #   user.public_send(ScimRails.config.user_deprovision_method) unless put_active?
    # end

    # def patch_update_status(user)
    #   return if patch_active.nil?
    #   user.public_send(ScimRails.config.user_reprovision_method) if patch_active?
    #   user.public_send(ScimRails.config.user_deprovision_method) unless patch_active?
    # end

    def update_status(user)
      user.public_send(ScimRails.config.user_reprovision_method) if active?
      user.public_send(ScimRails.config.user_deprovision_method) unless active?
    end

    def patch_status(active_param)
      case active_param
      when true, "true", 1
        true
      when false, "false", 0
        false
      else
        nil
      end
    end

    def active?
      active = put_active_param
      active = patch_active_param if active.nil?

      case active
      when true, "true", 1
        true
      when false, "false", 0
        false
      else
        raise ActiveRecord::RecordInvalid
      end
    end

    def put_active_param
      params[:active]
    end

    def patch_active_param
      active = params.dig("Operations", 0, "value", "active")
      raise ScimRails::ExceptionHandler::UnsupportedPatchRequest if active.nil?
      active
    end
  end
end
