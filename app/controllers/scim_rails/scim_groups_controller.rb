module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index
      # TODO: Add param functionality for filtering
      groups = @company
               .public_send(ScimRails.config.scim_groups_scope)
               .order(ScimRails.config.scim_groups_list_order)

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: groups.count
      )

      json_scim_group_response(object: groups, counts: counts)
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
