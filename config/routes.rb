ScimRails::Engine.routes.draw do
  get     'scim/v2/Users',                  action: :index,         controller: 'scim_users'
  post    'scim/v2/Users',                  action: :create,        controller: 'scim_users'
  get     'scim/v2/Users/:id',              action: :show,          controller: 'scim_users'
  put     'scim/v2/Users/:id',              action: :put_update,    controller: 'scim_users'
  patch   'scim/v2/Users/:id',              action: :patch_update,  controller: 'scim_users'
  delete  'scim/v2/Users/:id',              action: :delete,        controller: 'scim_users'

  get    'scim/v2/Groups',                 action: :index,          controller: 'scim_groups'
  post   'scim/v2/Groups',                 action: :create,         controller: 'scim_groups'
  get    'scim/v2/Groups/:id',             action: :show,           controller: 'scim_groups'
  put    'scim/v2/Groups/:id',             action: :put_update,     controller: 'scim_groups'
  patch  'scim/v2/Groups/:id',             action: :patch_update,   controller: 'scim_groups'
  delete 'scim/v2/Groups/:id',             action: :delete,         controller: 'scim_groups'

  get    'scim/v2/ServiceProviderConfig',  action: :configuration,  controller: 'scim_service'
  get    'scim/v2/ServiceProviderConfigs', action: :configuration,  controller: 'scim_service'

  get    'scim/v2/ResourceTypes/User',     action: :resource_user,  controller: 'scim_resource'
  get    'scim/v2/ResourceTypes/Group',    action: :resource_group, controller: 'scim_resource'
                             
  get    'scim/v2/Schemas/:id',            action: :get_schema,     controller: 'scim_schema'
end
