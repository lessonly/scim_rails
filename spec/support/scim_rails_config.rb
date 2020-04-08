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
  config.scim_users_list_order = :id

  config.signing_algorithm = "HS256"
  config.signing_secret = "2d6806dd11c2fece2e81b8ca76dcb0062f5b08e28e3264e8ba1c44bbd3578b70"

  config.user_deprovision_method = :archive!
  config.user_reprovision_method = :unarchive!

  config.mutable_user_attributes = [
    :first_name,
    :last_name,
    :email
  ]

  config.queryable_user_attributes = {
    userName: :email,
    givenName: :first_name,
    familyName: :last_name,
    email: :email
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
    ]
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
    active: :unarchived?
  }
end
