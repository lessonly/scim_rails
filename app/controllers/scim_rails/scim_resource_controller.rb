module ScimRails
  class ScimResourceController < ScimRails::ApplicationController
    def resource_user
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      ScimRails.config.after_scim_response.call(ScimRails.config.resource_user_schema, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: nil)
    end

    def resource_group
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      ScimRails.config.after_scim_response.call(ScimRails.config.resource_group_schema, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: nil)
    end
  end
end