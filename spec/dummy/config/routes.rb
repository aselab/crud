Dummy::Application.routes.draw do
  get '/' => "home#index", :as => :root

  resources :people
end
