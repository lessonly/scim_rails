module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        groups = @company.public_send(ScimRails.config.scim_groups_scope)
                         .where("#{ScimRails.config.scim_groups_model.connection.quote_column_name(query.group_attribute)} #{query.operator} ?", query.parameter)
                         .order(ScimRails.config.scim_groups_list_order)
      else
        groups = @company.public_send(ScimRails.config.scim_groups_scope)
                         .order(ScimRails.config.scim_groups_list_order)
      end

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: groups.count
      )

      json_scim_group_response(object: groups, counts: counts)
    end

    # TODO: complete method
    def create
      group = @company.public_send(ScimRails.config.scim_groups_scope).create!(permitted_group_params)

      json_scim_response(object: group, status: :created)
    end

    def show
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      json_scim_group_response(object: group)
    end

    # TODO: complete method
    def put_update

    end

    # TODO: complete method
    def patch_update

    end

    def delete
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      group.delete
      json_scim_group_response(object: nil, status: :no_content)
    end

    private

  end
end
