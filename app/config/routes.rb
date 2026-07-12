Rails.application.routes.draw do
  root "dashboard#show"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "dashboard", to: "dashboard#show"

  resources :service_requests, only: %i[index show new create] do
    patch :triage, on: :member
    patch :assign, on: :member
    patch :respond, on: :member
    patch :verify_completion, on: :member
  end
  resources :customers, only: %i[show]
  resources :customer_sites, only: %i[show]
  resources :dispatchers, only: %i[show], controller: :users
  resources :service_providers, only: %i[show]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "rails/health#show"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
