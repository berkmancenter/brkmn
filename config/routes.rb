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
    root 'devise/sessions#new', as: :anonymous_user_root
  end
  authenticated do
    root 'urls#index'
  end

  # So anything that doesn't match the resource controllers or the root path
  # goes to the redirector controller.

  get '/redirector/invalid' => 'redirector#invalid'

  get '/:id' => 'redirector#index', as: :shortened
end
