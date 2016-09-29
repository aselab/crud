Rails.application.routes.draw do
  namespace :ar do
    resources :companies
    resources :users
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
