ScimRails::Engine.routes.draw do
  get    'scim/v2/Users',      action: :index,        controller: 'scim_users'
  post   'scim/v2/Users',      action: :create,       controller: 'scim_users'
  get    'scim/v2/Users/:id',  action: :show,         controller: 'scim_users'
  put    'scim/v2/Users/:id',  action: :update,       controller: 'scim_users'
  patch  'scim/v2/Users/:id',  action: :deprovision,  controller: 'scim_users'
end
