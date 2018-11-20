ScimRails.configure do |config|
  config.basic_auth_model = "Company"
  config.scim_user_model = "User"
end
