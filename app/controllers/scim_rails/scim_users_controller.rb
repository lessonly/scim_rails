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

      if ScimRails.config.scim_user_prevent_update_on_create
        user = @company.public_send(ScimRails.config.scim_users_scope).create!(permitted_params(params))
      else
        username_key = ScimRails.config.queryable_user_attributes[:userName]

        find_by_username = Hash.new
        permitted_user_params = permitted_params(params)

        find_by_username[username_key] = permitted_user_params[username_key]
        user = @company
          .public_send(ScimRails.config.scim_users_scope)
          .find_or_create_by(find_by_username)
        user.update!(permitted_user_params)
      end
      update_status(user) unless put_active_param.nil?

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
      update_status(user) unless put_active_param.nil?
      user.update!(permitted_params(params))

      ScimRails.config.after_scim_response.call(user, "UPDATED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: user)
    end

    def patch_update
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])

      params["Operations"].each do |operation|
        raise ScimRails::ExceptionHandler::UnsupportedPatchRequest unless ["Replace", "replace"].include?(operation["op"])

        path_params = (operation.key?("path")) ? process_path(operation) : nil
        changed_attributes = permitted_params(path_params || operation["value"])

        user.update!(changed_attributes.compact)

        active_param = (operation.key?("path")) ? path_params&.dig(:active) : operation.dig("value", "active")
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
      user.delete

      ScimRails.config.after_scim_response.call(user, "DELETED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: nil, status: :no_content)
    end

    private

    def process_path(operation)
      keys = operation["path"].split('.').map { |key| key.to_sym }

      parsed_path = Hash.new
      key_chain = Array.new

      keys.each do |key|
        if key_chain.empty?
          parsed_path&.store(key, (key == keys.last) ? operation["value"] : {})
        else
          parsed_path.dig(*key_chain)&.store(key, (key == keys.last) ? operation["value"] : {})
        end

        key_chain << key
      end

      parsed_path
    end

    def permitted_params(parameters)
      ScimRails.config.mutable_user_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = parameters.dig(*path_for(attribute))
      end.merge(ScimRails.config.custom_user_attributes)
    end

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
  end
end
