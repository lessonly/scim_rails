module ScimRails
  module ExceptionHandler
    extend ActiveSupport::Concern

    class MissingCredentials < StandardError
    end

    class InvalidCredentials < StandardError
    end

    included do
      rescue_from ScimRails::ExceptionHandler::InvalidCredentials do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Authorization failure. The authorization header is invalid or missing.",
            status: "401"
          },
          :unauthorized
        )
      end

      rescue_from ScimRails::ExceptionHandler::MissingCredentials do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Authorization failure. The authorization header is invalid or missing.",
            status: "401"
          },
          :unauthorized
        )
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Resource #{e.id} not found.",
            status: "404"
          },
          :not_found
        )
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            scimType: "invalidValue",
            detail: e.message,
            status: "400"
          },
          :unprocessable_entity
        )
      end
    end
  end
end
