Rails.application.routes.draw do
  namespace :mongo do
    resources :groups
    resources :users
    resources :miscs
    resources :misc_belongings
  end
  namespace :ar do
    resources :groups
    resources :users
    resources :miscs
    resources :misc_belongings
  end

  post '/', to: "application#setting"
  root 'home#index'
end
