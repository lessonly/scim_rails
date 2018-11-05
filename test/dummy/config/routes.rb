Rails.application.routes.draw do
  mount ScimRails::Engine => "/scim_rails"
end
