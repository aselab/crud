Rails.application.routes.draw do
  namespace :mongo do
    resources :groups
    resources :users
    resources :miscs
    resources :misc_belongings
    resources :misc_habtms
  end
  namespace :ar do
    resources :groups
    resources :users
    resources :miscs
    resources :misc_belongings
    resources :misc_throughs
    resources :misc_habtms
  end

  post '/', to: "application#setting"
  root 'home#index'
end
