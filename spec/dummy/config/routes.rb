Rails.application.routes.draw do
  resources :mongo_users
  resources :users
  resources :groups
  root 'home#index'

end
