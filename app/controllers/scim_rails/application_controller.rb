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
  end
end
