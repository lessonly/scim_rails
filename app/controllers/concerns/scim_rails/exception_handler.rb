module ScimRails
  module ExceptionHandler
    extend ActiveSupport::Concern

    class InvalidCredentials < StandardError
    end

    class InvalidQuery < StandardError
    end

    class UnsupportedPatchRequest < StandardError
    end

    class InvalidPutMembers < StandardError
    end

    class InvalidActiveParam < StandardError
    end

    included do
      # StandardError must be ordered _first_ or it will catch all exceptions
      #
      # TODO: Build a plugin/configuration for error handling so that the
      # detailed production errors are logged somewhere if desired.
      if Rails.env.production?
        rescue_from StandardError do
          json_response(
            {
              schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
              status: "500"
            },
            :internal_server_error
          )
        end
      end

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

      rescue_from ScimRails::ExceptionHandler::UnsupportedPatchRequest do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Invalid PATCH request. This PATCH endpoint only supports deprovisioning and reprovisioning records.",
            status: "422"
          },
          :unprocessable_entity
        )
      end

      rescue_from ScimRails::ExceptionHandler::InvalidPutMembers do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Invalid PUT request. The 'members' attribute of the request must exist and be an array of hashes.",
            status: "400"
          },
          :bad_request
        )
      end

      rescue_from ScimRails::ExceptionHandler::InvalidActiveParam do
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Invalid request. The active param can only be 'true' or 'false'",
            status: "400"
          },
          :bad_request
        )
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        json_response(
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:Error"],
            detail: "Resource #{not_found_id_backport(e)} not found.",
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

      def not_found_class_name_backport(e)
        ActiveSupport::Deprecation.warn('not required in Rails 5+') if Rails.version >= '5'
        e.message.match(/find (.*?)\s/)[1].to_s
      rescue NoMethodError
        ""
      end

      def not_found_id_backport(e)
        ActiveSupport::Deprecation.warn('not required in Rails 5+') if Rails.version >= '5'
        e.message.match(/'id'=(.*?)\s/)[1].to_s
      rescue NoMethodError
        ""
      end
    end
  end
end
