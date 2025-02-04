# frozen_string_literal: true

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq)
  devise_for :users, controllers: { registrations: 'registrations' }

  resources :urls do
    collection do
      get 'url_list'
      get 'bookmarklet'
      get 'search'
    end
    member do
      get :qr
    end
  end

  resources :users do
    collection do
      get :cas_logout
    end
  end

  root to: redirect('/urls')

  # So anything that doesn't match the resource controllers or the root path
  # goes to the redirector controller.

  get '/redirector/invalid' => 'redirector#invalid'

  get '/toggle_mode' => 'theme#toggle_mode'

  get '/:id' => 'redirector#index', as: :shortened, id: /.*/

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
