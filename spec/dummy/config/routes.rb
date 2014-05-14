Rails.application.routes.draw do
  resources :users
  resources :groups
  root 'home#index'

end
