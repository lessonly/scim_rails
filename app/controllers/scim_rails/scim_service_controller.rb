module ScimRails
  class ScimServiceController < ScimRails::ApplicationController
    def configuration
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      ScimRails.config.after_scim_response.call(ScimRails.config.config_schema, "RETRIEVED") unless ScimRails.config.after_scim_response.nil?

      json_scim_response(object: nil)
    end
  end
end
