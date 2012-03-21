Brkmn::Application.routes.draw do

  resources :users

  resources :urls

  # So anything that doesn't match the resource controllers above goes to the redirector controller.
  # root :to => 'welcome#index'
end
