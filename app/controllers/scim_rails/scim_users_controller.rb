module ScimRails
  class ScimUsersController < ScimRails::ApplicationController
    def index
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        users = @company
          .public_send(ScimRails.config.scim_users_scope)
          .where(
            "#{ScimRails.config.scim_users_model.connection.quote_column_name(query.user_attribute)} #{query.operator} ?",
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

      ScimRails.config.after_scim_response.call(users, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: users, counts: counts)
    end

    def create
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user_params = permitted_params(params, "User").merge(multi_attr_type_to_value(params))

      if ScimRails.config.scim_user_prevent_update_on_create
        user = @company.public_send(ScimRails.config.scim_users_scope).create!(user_params)
      else
        username_key = ScimRails.config.queryable_user_attributes[:userName]

        find_by_params = Hash.new

        find_by_params[username_key] = user_params[username_key]
        find_by_params[ScimRails.config.basic_auth_model.to_s.underscore] = @company

        user = ScimRails.config.scim_users_model
          .unscoped # Specific to our use case and should be changed back after we remove the default_scope from our "User" model
          .find_or_initialize_by(find_by_params)
        user.update!(user_params)
      end
      update_status(user) unless params[:active].nil?

      ScimRails.config.after_scim_response.call(user, "CREATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: user, status: :created)
    end

    def show
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])

      ScimRails.config.after_scim_response.call(user, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: user)
    end

    def put_update
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])

      user_params = permitted_params(params, "User").merge(multi_attr_type_to_value(params))
      user.update!(user_params)

      update_status(user) unless params[:active].nil?

      ScimRails.config.after_scim_response.call(user, "UPDATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: user)
    end

    def patch_update
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])

      params["Operations"].each do |operation|
        raise ScimRails::ExceptionHandler::UnsupportedPatchRequest unless ["replace", "add", "remove"].include?(operation["op"].downcase)

        path_params = extract_path_params(operation)
        changed_attributes = permitted_params(path_params || operation["value"], "User").merge(get_multi_value_attrs(operation))

        user.update!(changed_attributes.compact)

        active_param = extract_active_param(operation, path_params)
        status = patch_status(active_param)
        
        next if status.nil?

        provision_method = status ? ScimRails.config.user_reprovision_method : ScimRails.config.user_deprovision_method
        user.public_send(provision_method)
      end

      ScimRails.config.after_scim_response.call(user, "UPDATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: user)
    end

    def delete
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      user.update!(ScimRails.config.custom_user_attributes)
      
      user.destroy

      ScimRails.config.after_scim_response.call(user, "DELETED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: nil, status: :no_content)
    end

    private

    def get_multi_value_attrs(operation)
      schema_hash = contains_square_brackets?(operation["path"]) ? multi_attr_type_to_value(process_filter_path(operation)) : {}
    end
  end
end
