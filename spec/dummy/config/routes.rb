Rails.application.routes.draw do
  resources :mongo_users
  resources :mongo_groups do
    resources :mongo_resources
  end
  resources :users
  resources :groups
  root 'home#index'

end
