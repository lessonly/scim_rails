module ScimRails
  class ScimUsersController < ScimRails::ApplicationController
    def index
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        users = @company.public_send(ScimRails.config.scim_users_scope).where(
          "#{ScimRails.config.scim_users_model.connection.quote_column_name(query.attribute)} #{query.operator} ?",
          query.parameter
        )

        counts = ScimCount.new(
          start_index: params[:startIndex],
          limit: params[:count],
          total: users.count
        )
        json_scim_response(object: users, counts: counts)
      else
        users = @company.public_send(ScimRails.config.scim_users_scope)

        counts = ScimCount.new(
          start_index: params[:startIndex],
          limit: params[:count],
          total: users.count
        )

        json_scim_response(object: users, counts: counts)
      end
    end

    def create
      user = @company.public_send(ScimRails.config.scim_users_scope).new
      user.create!(permitted_user_params)

      json_scim_response(object: user, status: :created)
    end

    def show
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      json_scim_response(object: user)
    end

    def update
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      update_status(user) unless params[:active].nil?
      user.update!(permitted_user_params)
      json_scim_response(object: user)
    end

    def deprovision
      user = @company.public_send(ScimRails.config.scim_users_scope).find(params[:id])
      update_status(user) unless params[:active].nil?
      json_scim_response(object: user)
    end

    private

    def permitted_user_params
      ScimRails.config.mutable_user_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = find_value_for(attribute)
      end
    end

    def find_value_for(attribute)
      params.dig(*path_for(attribute))
    end

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

    def update_status(user)
      user.public_send(ScimRails.config.user_reprovision_method) if active?
      user.public_send(ScimRails.config.user_deprovision_method) unless active?
    end

    def active?
      case params[:active]
      when true, "true", 1
        true
      when false, "false", 0
        false
      else
        raise ActiveRecord::RecordInvalid
      end
    end
  end
end
