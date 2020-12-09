# This file would normally be in config > initializers but
# is included here because it is essentially a spec helper

ScimRails.configure do |config|
  config.basic_auth_model = "Company"
  config.scim_users_model = "User"
  config.scim_groups_model = "Group"

  config.basic_auth_model_searchable_attribute = :subdomain
  config.basic_auth_model_authenticatable_attribute = :api_token
  config.scim_users_scope = :users
  config.scim_groups_scope = :groups

  config.scim_group_member_scope = :users

  config.scim_users_list_order = :id
  config.scim_groups_list_order = :id

  config.signing_algorithm = "HS256"
  config.signing_secret = "2d6806dd11c2fece2e81b8ca76dcb0062f5b08e28e3264e8ba1c44bbd3578b70"

  config.user_deprovision_method = :archive!
  config.user_reprovision_method = :unarchive!

  config.group_deprovision_method = :archive!
  config.group_reprovision_method = :unarchive!

  config.mutable_user_attributes = [
    :first_name,
    :last_name,
    :email,
    :test_attribute,
  ]

  config.mutable_group_attributes = [
    :display_name,
    :email,
    :members,
  ]

  config.queryable_user_attributes = {
    userName: :email,
    givenName: :first_name,
    familyName: :last_name,
    email: :email,
    testAttribute: :test_attribute,
  }

  config.queryable_group_attributes = {
    userName: :display_name,
    displayName: :display_name,
    email: :email,
  }

  config.mutable_user_attributes_schema = {
    name: {
      givenName: :first_name,
      familyName: :last_name
    },
    emails: [
      {
        value: :email
      }
    ],
    testAttribute: :test_attribute,
  }

  config.mutable_group_attributes_schema = {
    displayName: :display_name,
    email: :email,
    members: :members,
  }

  config.user_schema = {
    schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
    id: :id,
    userName: :email,
    name: {
      givenName: :first_name,
      familyName: :last_name
    },
    emails: [
      {
        value: :email
      },
    ],
    testAttribute: :test_attribute,
    active: :unarchived?,
  }

  config.group_schema = {
    schemas: ["urn:ietf:params:scim:schemas:core:2.0:Group"],
    id: :id,
    userName: :display_name,
    displayName: :display_name,
    email: :email,
    members: [],
    active: :unarchived?,
  }

  config.group_member_schema = {
    value: :id,
  }

  # config.before_scim_response = lambda do |body|
  #   print "BEFORE SCIM RESPONSE #{body}"
  # end

  # config.after_scim_response = lambda do |object, status|
  #   print "#{object} #{status}"
  # end

  config.scim_attribute_type_mappings = {
    "emails" => {
      "work" => :email,
      "other" => :alternate_email,
    },
  }

  config.config_schema = {
    schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
    patch: {
      supported: true
    },
    bulk: {
      supported: false,
      maxOperations: 0,
      maxPayloadSize: 0
    },
    filter: {
      supported: true,
    },
    changePassword: {
      supported: false
    },
    sort: {
      supported: true
    },
    etag: {
      supported: false
    },
    authenticationSchemes: [
      {
        type: "oauthbearertoken",
        name: "Oauth Bearer Token",
        description: "Authentication scheme using the OAuth Bearer Token Standard"
      },
      {
        type: "httpbasic",
        name: "HTTP Basic",
        description: "Authentication scheme using the HTTP Basic Standard"
      }
    ]
  }

  config.resource_user_schema = {
    schemas: ["urn:ietf:params:scim:schemas:core:2.0:ResourceType"],
    id: "User",
    name: "User",
    endpoint: "/Users",
    schema: "urn:ietf:params:scim:schemas:core:2.0:User"
  }

  config.resource_group_schema = {
    schemas: ["urn:ietf:params:scim:schemas:core:2.0:ResourceType"],
    id: "Group",
    name: "Group",
    endpoint: "/Groups",
    schema: "urn:ietf:params:scim:schemas:core:2.0:Group"
  }
end
