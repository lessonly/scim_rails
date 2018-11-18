module ScimRails
  module ExceptionHandler
    extend ActiveSupport::Concern

    class MissingCredentials < StandardError
    end

    class InvalidCredentials < StandardError
    end

    included do
      rescue_from ScimRails::ExceptionHandler::InvalidCredentials do
        json_response({ message: "Invalid credentials" }, :unauthorized)
      end

      rescue_from ScimRails::ExceptionHandler::MissingCredentials do
        json_response({ message: "Missing credentials" }, :unauthorized)
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        json_response({ message: e.message }, :not_found)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        json_response({ message: e.message }, :unprocessable_entity)
      end
    end
  end
end
