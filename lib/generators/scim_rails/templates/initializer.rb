ScimRails.configure do |config|
  # Model used for authenticating and scoping users.
  config.basic_auth_model = "Company"

  # Attribute used to search for a given record. This
  # attribute should be unique as it will return the
  # first found record.
  config.basic_auth_model_searchable_attribute = :subdomain

  # Attribute used to compare Basic Auth password value.
  # Attribute will need to return plaintext for comparison.
  config.basic_auth_model_authenticatable_attribute = :api_token

  # Model used for user records.
  config.scim_users_model = "User"

  # Metod used for retriving user records from the
  # authenticatable model.
  config.scim_users_scope = :users

  # Default sort order for pagination is by id. If you
  # use non sequential ids for user records, uncomment
  # the below line and configure a determinate order.
  # For example, [:created_at, :id] or { created_at: :desc }.
  # config.scim_users_list_order = :id

  # Method called on user model to deprovision a user.
  config.user_deprovision_method = :archive!

  # Method called on user model to reprovision a user.
  config.user_reprovision_method = :unarchive!

  # Hash of queryable attribtues on the user model. If
  # the attribute is not listed in this hash it cannot
  # be queried by this Gem. The structure of this hash
  # is { queryable_scim_attribute => user_attribute }. 
  config.queryable_user_attributes = {
    userName: :email,
    givenName: :first_name,
    familyName: :last_name,
    email: :email
  }

  # Array of attributes that can be modified on the
  # user model. If the attribute is not in this array
  # the attribute cannot be modified by this Gem.
  config.mutable_user_attributes = [
    :first_name,
    :last_name,
    :email
  ]

  # Hash of mutable attributes. This object is the map
  # for this Gem to figure out where to look in a SCIM
  # response for mutable values. This object should
  # include all attributes listed in
  # config.mutable_user_attributes. 
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

  # Hash of SCIM structure for a user schema. This object
  # is what will be returned for a given user. The keys
  # in this object should conform to standard SCIM
  # structures. The values in the object will be
  # transformed per user record. Strings will be passed
  # through as is, symbols will be passed to the user
  # object to return a value.
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
    active: :active?
  }
end
