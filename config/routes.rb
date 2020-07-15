Rails.application.routes.draw do
  devise_for :users
  resources :urls do
    collection do
      get 'url_list'
      get 'bookmarklet'
  	  get 'search'
    end
  end
  unauthenticated do
    as :user do
      root to: 'devise/sessions#new', as: :anonymous_root
    end
  end

  root to: 'urls#index'

  # So anything that doesn't match the resource controllers or the root path
  # goes to the redirector controller.

  get '/redirector/invalid' => 'redirector#invalid'

  get '/:id' => 'redirector#index', as: :shortened
end
