module ScimRails
  class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ExceptionHandler
    include Response

    before_action :authorize_request

    private

    def authorize_request
      send(authentication_strategy) do |searchable_attribute, authentication_attribute|
        authorization = AuthorizeApiRequest.new(
          searchable_attribute: searchable_attribute,
          authentication_attribute: authentication_attribute
        )
        @company = authorization.company
      end
      raise ScimRails::ExceptionHandler::InvalidCredentials if @company.blank?
    end

    def authentication_strategy
      if request.headers["Authorization"]&.include?("Bearer")
        :authenticate_with_oauth_bearer
      else
        :authenticate_with_http_basic
      end
    end

    def authenticate_with_oauth_bearer
      authentication_attribute = request.headers["Authorization"].split(" ").last
      payload = ScimRails::Encoder.decode(authentication_attribute).with_indifferent_access
      searchable_attribute = payload[ScimRails.config.basic_auth_model_searchable_attribute]

      yield searchable_attribute, authentication_attribute
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

    def path_for(attribute, object = controller_schema, path = [])
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
