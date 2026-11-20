# frozen_string_literal: true

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq)
  devise_for :users, controllers: { registrations: 'registrations' }

  resources :urls do
    resources :collaborators, only: %i[create destroy], controller: "url_collaborators"
    resources :access_requests, only: %i[create update], controller: "url_access_requests"
    collection do
      get 'url_list'
      get 'bookmarklet'
      get 'search'
    end
    member do
      get :details
      get :qr
    end
  end

  resources :users do
    collection do
      get :cas_logout
    end
  end

  # The single-use link external users get by email (?token=... so the value is
  # filtered out of the request logs). Keep it below /api so the public API
  # exception in an authenticating proxy also lets external users reach it.
  # This must stay above the API catch-all routes.
  resource :api_token_claim, only: %i[show create], path: "api/token_claim"

  # Links sent before the public path changed still work when they reach Rails.
  resource :legacy_api_token_claim,
    only: %i[show create],
    path: "api_tokens/claim",
    controller: "api_token_claims"

  # JSON API. Must stay above the catch-all redirector route at the bottom.
  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      get "me" => "me#show"
      resources :urls, only: %i[index show create update destroy] do
        get :qr, on: :member
      end
    end
    match "/" => "v1/base#route_not_found", via: :all
    match "*path" => "v1/base#route_not_found", via: :all
  end

  get "settings" => redirect("/settings/api_tokens"), as: :settings
  scope path: "settings" do
    resources :api_tokens, only: %i[index create] do
      member do
        post :regenerate
        patch :revoke
      end
    end

    namespace :admin do
      resources :api_tokens, only: %i[index new create] do
        member do
          patch :revoke
          post :reissue
        end
      end
    end
  end

  root to: redirect('/urls')

  get '/redirector/invalid' => 'redirector#invalid'

  get '/toggle_mode' => 'theme#toggle_mode'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # So anything that doesn't match the routes above goes to the redirector
  # controller. Keep this route last, it matches every path.
  get '/:id' => 'redirector#index', as: :shortened, id: /.*/
end
