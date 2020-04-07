ScimRails::Engine.routes.draw do
  get    'scim/v2/Users',      action: :index,         controller: 'scim_users'
  post   'scim/v2/Users',      action: :create,        controller: 'scim_users'
  get    'scim/v2/Users/:id',  action: :show,          controller: 'scim_users'
  put    'scim/v2/Users/:id',  action: :put_update,    controller: 'scim_users'
  patch  'scim/v2/Users/:id',  action: :patch_update,  controller: 'scim_users'

  get    'scim/v2/Groups',      action: :index,         controller: 'scim_groups'
  post   'scim/v2/Groups',      action: :create,        controller: 'scim_groups'
  get    'scim/v2/Groups/:id',  action: :show,          controller: 'scim_groups'
  put    'scim/v2/Groups/:id',  action: :put_update,    controller: 'scim_groups'
  patch  'scim/v2/Groups/:id',  action: :patch_update,  controller: 'scim_groups'
end
