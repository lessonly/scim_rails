module ScimRails
  module ExceptionHandler
    extend ActiveSupport::Concern

    class MissingCredentials < StandardError
    end

    class InvalidCredentials < StandardError
    end

    class InvalidQuery < StandardError
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

      rescue_from ScimRails::ExceptionHandler::InvalidQuery do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            scimType: "invalidFilter",
            detail: "The specified filter syntax was invalid, or the specified attribute and filter comparison combination is not supported.",
            status: "400"
          },
          :bad_request
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
        case e.message
        when /has already been taken/
          json_response(
            {
              schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
              detail: e.message,
              status: "409"
            },
            :conflict
          )
        else
          json_response(
            {
              schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
              detail: e.message,
              status: "422"
            },
            :unprocessable_entity
          )
        end
      end

      ## StandardError must be ordered last or it will catch all exceptions
      if Rails.env.production?
        rescue_from StandardError do |e|
          json_response(
            {
              schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
              detail: e.message,
              status: "500"
            },
            :internal_server_error
          )
        end
      end
    end
  end
end
