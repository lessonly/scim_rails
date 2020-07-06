module ScimRails
  class ApplicationController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ExceptionHandler
    include Response

    before_action :authorize_request
    protect_from_forgery with: :null_session

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
    
    # Shared stuff...

    def contains_square_brackets?(string)
      !(string =~ /\[.*\]/).nil?
    end

    def before_square_brackets(string)
      string.match(/([^\[]+)/).to_s
    end

    def inside_square_brackets(string)
      string.match(/(?<=\[).+?(?=\])/).to_s
    end

    def after_square_brackets(string)
      string.match(/(?<=\]).*/).to_s
    end

    def inside_quotations(string)
      string.match(/(?<=")[^"]+(?=")/).to_s
    end

    def extract_path_params(operation)
      operation.key?("path") ? process_path(operation) : nil
    end

    def extract_active_param(operation, path_params)
      operation.key?("path") ? path_params&.dig(:active) : operation.dig("value", "active")
    end

    # `process_path` is a method that parses the string in the "path"
    # key of a PATCH operation. Together with the "value" key, it
    # converts it into a Hash that can be used in the `permitted_params`
    # method to help update the attributes of a User or Group.
    #
    # Example: given the following operation:
    #   operation = {
    #     'op': 'Replace',
    #     'path': 'name.givenName',
    #     'value': 'Grayson'
    #   }
    # calling `process_path(operation)` will return the Hash:
    #   {
    #     name: {
    #       givenName: 'Grayson'
    #     }
    #   }
    # which can easily be processed by `permitted_params` which will get
    # the attributes that will be updated by the PATCH request
    def process_path(operation)
      keys = operation["path"].split('.').map { |key| key.to_sym }

      keys.each_with_index.reduce({}) do |acc, (key, index)|
        value = key == keys.last ? operation["value"] : {}

        if index.zero?
          acc.store(key, value)
        else
          key_path = keys.slice(0..(index - 1))
          acc.dig(*key_path)&.store(key, value)
        end

        acc
      end
    end

    # `process_filter_path` is a method that, like the `process_path`
    # method above, parses the string in the "path" key of a PATCH
    # operation.  It converts the operation into a Hash that resembles
    # the User or Group schema, and it will be easier to fetch
    # attributes needed to update a user or group.
    #
    # Example: given the following operation:
    #   operation = {
    #     'op': 'Add',
    #     'path': 'emails[type eq \'work\'].value',
    #     'value': 'Wolfe'
    #   }
    # then calling `process_filter_path(operation)` will return the
    # Hash:
    #   {
    #     emails: [
    #       {
    #         type: 'work'
    #         value: 'Wolfe'
    #       }
    #     ]
    #   }
    # which will will later be processed to fetch the attributes to be
    # updated by the PATCH request
    def process_filter_path(operation)
      path_string = operation["path"]

      pre_bracket_path = before_square_brackets(path_string)
      filter = inside_square_brackets(path_string)

      args = filter.split(' ')

      key = args[0]
      value = inside_quotations(args[2])

      inner_hash = {}
      inner_hash[key] = value
      inner_hash["value"] = operation["value"]

      full_hash = {}
      full_hash[pre_bracket_path] = [ inner_hash ]

      full_hash
    end
    
    # `path_for` is a recursive method used to find the "path" for
    # `.dig` to take when looking for a given attribute in the
    # params.
    #
    # Example: `path_for(:name)` should return an array that looks
    # like [:names, 0, :givenName]. `.dig` can then use that path
    # against the params to translate the :name attribute to "John".
    def path_for(attribute, object = ScimRails.config.mutable_user_attributes_schema, path = [])
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

    def active?
      active = put_active_param
      active = patch_active_param if active.nil?

      case active
      when true, "true", 1
        true
      when false, "false", 0
        false
      else
        raise ActiveRecord::RecordInvalid
      end
    end

    def put_active_param
      params[:active]
    end

    def patch_active_param
      active = params.dig("Operations", 0, "value", "active")
      raise ScimRails::ExceptionHandler::UnsupportedPatchRequest if active.nil?
      active
    end
  end
end
