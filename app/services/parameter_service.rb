module ParameterService
  extend self

  KEYS_TO_IGNORE = [
    # Rails Common
    'action',
    'controller',

    # patch
    'Operations',
  ].freeze

  # https://datatracker.ietf.org/doc/html/rfc7643#section-4
  SCIM_CORE_USER_SCHEMA = {
    "id" => :value,
    "userName" => :value,
    "externalId" => :value,
    "active" => :value,
    "addresses" => [],
    "costCenter" => :value,
    "department" => :value,
    "displayName" => :value,
    "division" => :value,
    "emails" => [],
    "employeeNumber" => :value,
    "entitlements" => [],
    "groups" => [],
    "ims" => [],
    "locale" => :value,
    "meta" => {
      "resourceType" => :value,
      "created" => :value,
      "lastModified" => :value,
      "location" => :value,
      "version" => :value,
    },
    "name" => {
      "formatted" => :value,
      "familyName" => :value,
      "givenName" => :value,
      "middleName" => :value,
      "honorificPrefix" => :value,
      "honorificSuffix" => :value,
    },
    "nickName" => :value,
    "organization" => :value,
    "password" => :value,
    "phoneNumbers" => [],
    "photos" => [],
    "preferredLanguage" => :value,
    "profileUrl" => :value,
    "roles" => [],
    "timezone" => :value,
    "title" => :value,
    "userType" => :value,
    "x509Certificates" => [],
  }

  # Given a schema and a parameter hash this method
  # will return an aray of parameters that do not exist
  # or have a mismatched type in the schema
  def invalid_parameters(schema, parameters, parent_path: nil)
    invalid = []

    if parameters.is_a?(ActionController::Parameters)
      parameters = parameters.deep_dup
      parameters.permit!
      parameters = parameters.to_hash
    end

    parameters.each do |param_key, param_value|
      next if param_key.match?(/^urn:ietf:params:scim:/i)
      next if parent_path.nil? && KEYS_TO_IGNORE.include?(param_key)
      param_path = [parent_path, param_key.to_s].compact.join(".")

      unless schema.has_key?(param_key.to_s)
        invalid << param_path
        next
      end

      # Okay... both keys exist.. Did either side specify a subtype?
      sub_schema = schema[param_key.to_s]
      param_has_subtype = sub_schema.is_a?(Hash) || param_value.is_a?(Hash)
      param_has_subtype ||= sub_schema.is_a?(Array) || param_value.is_a?(Array)
      next unless param_has_subtype

      if param_value.is_a?(Array) && sub_schema.is_a?(Array)
        next
      elsif param_value.is_a?(Hash) && sub_schema.is_a?(Hash)
        invalid += invalid_parameters(sub_schema, param_value, parent_path: param_path)
      else
        # One, and only one, of them is a subtype so it is invalid
        invalid << param_path
      end
    end
    invalid
  end
end
