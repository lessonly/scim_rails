module ScimRails
  class ScimSchemaController < ApplicationController
    def get_schema
      ScimRails.config.before_scim_response.call(request.params) unless ScimRails.config.before_scim_response.nil?

      if request.params[:id] == "urn:ietf:params:scim:schemas:core:2.0:User"
        object = ScimRails.config.retrievable_user_schema
      elsif request.params[:id] == "urn:ietf:params:scim:schemas:core:2.0:Group"
        object = ScimRails.config.retrievable_group_schema
      else
        object = {}
      end

      ScimRails.config.after_scim_response.call(object, “RETRIEVED”) unless ScimRails.config.after_scim_response.nil?
      
      json_schema_response(object)
    end
  end
end
