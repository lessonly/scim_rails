# frozen_string_literal: true

module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController
    def index
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(
          params[:filter], ScimRails.config.queryable_group_attributes
        )

        groups = @company
          .public_send(ScimRails.config.scim_groups_scope)
          .where(
            "#{ScimRails.config.scim_groups_model.connection.quote_column_name(query.attribute)} #{query.operator} ?",
            query.parameter
          )
          .order(ScimRails.config.scim_groups_list_order)
      else
        groups = @company
          .public_send(ScimRails.config.scim_groups_scope)
          .preload(:users)
          .order(ScimRails.config.scim_groups_list_order)
      end

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: groups.count
      )

      json_scim_response(object: groups, counts: counts)
    end

    def show
      group = @company
        .public_send(ScimRails.config.scim_groups_scope)
        .find(params[:id])
      json_scim_response(object: group)
    end

    def create
      group = @company
        .public_send(ScimRails.config.scim_groups_scope)
        .create!(permitted_group_params)

      json_scim_response(object: group, status: :created)
    end

    def put_update
      group = @company
        .public_send(ScimRails.config.scim_groups_scope)
        .find(params[:id])
      group.update!(permitted_group_params)
      json_scim_response(object: group)
    end

    def destroy
      unless ScimRails.config.group_destroy_method
        raise ScimRails::ExceptionHandler::UnsupportedDeleteRequest
      end
      group = @company
        .public_send(ScimRails.config.scim_groups_scope)
        .find(params[:id])
      group.public_send(ScimRails.config.group_destroy_method)
      head :no_content
    end

    private

    def permitted_group_params
      converted = mutable_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = find_value_for(attribute)
      end
      return converted unless params[:members]

      converted.merge(member_params)
    end

    def member_params
      {
        ScimRails.config.group_member_relation_attribute =>
          params[:members].map do |member|
            member[ScimRails.config.group_member_relation_schema.keys.first]
          end
      }
    end

    def mutable_attributes
      ScimRails.config.mutable_group_attributes
    end

    def controller_schema
      ScimRails.config.mutable_group_attributes_schema
    end
  end
end
