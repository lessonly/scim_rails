module ScimRails
  class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ExceptionHandler
    include Response

    before_action :authorize_request

    private

    def authorize_request
      authenticate_with_http_basic do |username, password|
        authorization = AuthorizeApiRequest.new(
          subdomain: username,
          api_key: password
        )
        @company = authorization.company
      end
    end
  end
end
