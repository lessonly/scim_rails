ScimRails.configure do |config|
  config.basic_auth_model = "Company"
  config.scim_users_model = "User"
  config.user_attributes = []
end
