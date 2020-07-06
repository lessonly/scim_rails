module ScimRails
  class << self
    def configure
      yield config
    end

    def config
      @_config ||= Config.new
    end
  end

  class Config
    ALGO_NONE = "none".freeze

    attr_accessor \
      :basic_auth_model,
      :basic_auth_model_authenticatable_attribute,
      :basic_auth_model_searchable_attribute,
      :mutable_user_attributes,
      :mutable_group_attributes,
      :mutable_user_attributes_schema,
      :mutable_group_attributes_schema,
      :queryable_user_attributes,
      :queryable_group_attributes,
      :scim_users_list_order,
      :scim_groups_list_order,
      :scim_users_model,
      :scim_groups_model,
      :scim_users_scope,
      :scim_groups_scope,
      :scim_group_member_scope,
      :scim_user_prevent_update_on_create,
      :scim_group_prevent_update_on_create,
      :signing_secret,
      :signing_algorithm,
      :user_attributes,
      :user_deprovision_method,
      :user_reprovision_method,
      :group_deprovision_method,
      :group_reprovision_method,
      :user_schema,
      :group_schema,
      :group_member_schema,
      :group_attributes,
      :custom_user_attributes,
      :custom_group_attributes,
      :before_scim_response,
      :after_scim_response,
      :scim_attribute_type_mappings,

    def initialize
      @basic_auth_model = "Company"
      @scim_users_list_order = :id
      @scim_groups_list_order = :id
      @scim_users_model = "User"
      @signing_algorithm = ALGO_NONE
      @user_schema = {}
      @group_schema = {}
      @user_attributes = []
      @group_attributes = []
      @custom_user_attributes = {}
      @custom_group_attributes = {}
    end

    def mutable_user_attributes_schema
      @mutable_user_attributes_schema || @user_schema
    end

    def basic_auth_model
      @basic_auth_model.constantize
    end

    def scim_users_model
      @scim_users_model.constantize
    end

    def scim_groups_model
      @scim_groups_model.constantize
    end
  end
end
