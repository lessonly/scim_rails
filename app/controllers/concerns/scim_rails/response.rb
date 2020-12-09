module ScimRails
  # TODO: Cut down on redundant code in this file
  module Response
    CONTENT_TYPE = "application/scim+json".freeze

    def json_response(object, status = :ok)
      render \
        json: object,
        status: status,
        content_type: CONTENT_TYPE
    end

    def json_scim_response(object:, status: :ok, counts: nil)
      response = nil
      case params[:action]
      when "index"
        response = list_response(object, counts)
      when "show", "create", "put_update", "patch_update"
        response = user_response(object)
      when "delete"
        head status
        return
      when "configuration"
        response = ScimRails.config.config_schema
      when "resource_user"
        response = ScimRails.config.resource_user_schema
      when "resource_group"
        response = ScimRails.config.resource_group_schema
      end

      render \
        json: response,
        status: status,
        content_type: CONTENT_TYPE
    end

    def json_schema_response(object)
      render \
        json: object,
        status: :ok,
        content_type: CONTENT_TYPE
    end

    def json_scim_group_response(object:, status: :ok, counts: nil)
      response = nil
      case params[:action]
      when "index"
        response = list_group_response(object, counts)
      when "show", "create", "put_update", "patch_update"
        response = group_response(object)
      when "delete"
        head status
        return
      end

      render \
        json: response,
        status: status,
        content_type: CONTENT_TYPE
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

    def list_group_response(object, counts)
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
        "Resources": list_groups(object)
      }
    end

    def list_users(users)
      users.map do |user|
        user_response(user)
      end
    end

    def list_groups(groups)
      groups.map do |group|
        group_response(group)
      end
    end

    def user_response(user)
      schema = ScimRails.config.user_schema
      find_value(user, schema)
    end

    # Convert each group into defined scim schema
    def group_response(group)
      schema = ScimRails.config.group_schema

      json_scim = find_value(group, schema)

      group_members = group.public_send(ScimRails.config.scim_group_member_scope)
      member_schema = ScimRails.config.group_member_schema

      group_members.each do |member|
        json_scim[:members] << find_value(member, member_schema)
      end

      json_scim
    end

    # `find_value` is a recursive method that takes a "user" and a
    # "user schema" and replaces any symbols in the schema with the
    # corresponding value from the user. Given a schema with symbols,
    # `find_value` will search through the object for the symbols,
    # send those symbols to the model, and replace the symbol with
    # the return value.

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
