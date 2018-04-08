Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :users, only: [:create, :update]
  resources :routes, only: [:create]
  resources :routes, only: [:create] do
    member do
      get 'configure', to: :configure
    end
  end
end
