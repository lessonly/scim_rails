module ScimRails
  class ScimSchemaController < ApplicationController
    def get_schema
      ScimRails.config.before_scim_response.call(request.params) if ScimRails.config.before_scim_response.respond_to?(:call)

      id = request.params.key?("format") ? "#{request.params[:id]}.#{request.params[:format]}" : request.params[:id]

      if id == "urn:ietf:params:scim:schemas:core:2.0:User"
        object = ScimRails.config.retrievable_user_schema
      elsif id == "urn:ietf:params:scim:schemas:core:2.0:Group"
        object = ScimRails.config.retrievable_group_schema
      else
        object = {}
      end

      ScimRails.config.after_scim_response.call(object, "RETRIEVED") if ScimRails.config.after_scim_response.respond_to?(:call)
      
      json_schema_response(object)
    end
  end
end
