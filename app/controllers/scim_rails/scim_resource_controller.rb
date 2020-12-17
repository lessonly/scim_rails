module ScimRails
  class ScimResourceController < ScimRails::ApplicationController
    def resource_user
      ScimRails.config.before_scim_response.call(request.params) if ScimRails.config.before_scim_response.respond_to?(:call)

      ScimRails.config.after_scim_response.call(ScimRails.config.resource_user_schema, "RETRIEVED") if ScimRails.config.after_scim_response.respond_to?(:call)

      json_scim_response(object: nil)
    end

    def resource_group
      ScimRails.config.before_scim_response.call(request.params) if ScimRails.config.before_scim_response.respond_to?(:call)

      ScimRails.config.after_scim_response.call(ScimRails.config.resource_group_schema, "RETRIEVED") if ScimRails.config.after_scim_response.respond_to?(:call)

      json_scim_response(object: nil)
    end
  end
end