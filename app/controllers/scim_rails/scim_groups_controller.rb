module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index

    end

    def create
      group = @company.public_send(ScimRails.config.scim_group_scope).create!(permitted_group_params)

      json_scim_response(object: group, status: :created)
    end

    def show
      
    end

    def put_update

    end

    def patch_update

    end

    private

    def permitted_group_params
      params.permit()
    end
  end
end
