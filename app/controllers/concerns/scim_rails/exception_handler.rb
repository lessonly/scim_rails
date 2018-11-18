module ScimRails
  module ExceptionHandler
    extend ActiveSupport::Concern

    class MissingCredentials < StandardError
    end

    class InvalidCredentials < StandardError
    end

    included do
      rescue_from ScimRails::ExceptionHandler::InvalidCredentials do
        scim_response({ message: "Invalid credentials" }, :unauthorized)
      end

      rescue_from ScimRails::ExceptionHandler::MissingCredentials do
        scim_response({ message: "Missing credentials" }, :unauthorized)
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        scim_response({ message: e.message }, :not_found)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        scim_response({ message: e.message }, :unprocessable_entity)
      end
    end
  end
end
