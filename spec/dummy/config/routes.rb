Rails.application.routes.draw do
  namespace :pickers do
    namespace :ar do
      resources :miscs, only: :index
      resources :misc_belongings, only: :index
      resources :misc_habtms, only: :index
    end

    namespace :mongo do
      resources :miscs, only: :index
      resources :misc_belongings, only: :index
      resources :misc_habtms, only: :index
    end
  end

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
    resources :wizard_miscs, only: [:new, :create]
  end

  post '/', to: "application#setting"
  root 'home#index'
end
