module ScimRails
  module Response
    CONTENT_TYPE = "application/scim+json, application/json".freeze

    def json_response(object, status = :ok)
      render \
        json: object,
        status: status
    end

    def json_scim_response(object:, status: :ok, counts: nil)
      case params[:action]
      when "index"
        render \
          json: list_response(object, counts),
          status: status,
          content_type: CONTENT_TYPE
      when "show", "create", "update"
        render \
          json: user_response(object),
          status: status,
          content_type: CONTENT_TYPE
      end
    end

    private

    def list_response(object, counts)
      object = object
        .order(:id)
        .offset(counts.offset)
        .limit(counts.limit)
      {
        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        ],
        "totalResults": counts.total,
        "startIndex": counts.start_index,
        "itemsPerPage": counts.limit,
        "Resources": list_users(object)
      }
    end

    def list_users(users)
      users.map do |user|
        user_response(user)
      end
    end

    def user_response(user)
      schema = ScimRails.config.user_schema
      find_value(user, schema)
    end

    def find_value(user, object)
      case object
      when Hash
        object.each.with_object({}) do |(key, value), hash|
          hash[key] = find_value(user, value)
        end
      when Array
        object.map do |value|
          find_value(user, value)
        end
      when Symbol
        user.public_send(object)
      else
        object
      end
    end
  end
end
