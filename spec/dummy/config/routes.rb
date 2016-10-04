Rails.application.routes.draw do
  namespace :mongo do
    resources :groups
    resources :users
  end
  namespace :ar do
    resources :groups
    resources :users
  end

  post '/', to: "application#setting"
  root 'home#index'
end
