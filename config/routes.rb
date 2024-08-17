Rails.application.routes.draw do
  resources :assistants
  devise_for :users
  root to: 'chat#index'
  resources :chat, only: %i[create index]
  post '/chat', to: 'chat#create', as: 'create_chat'

  resources :ai_threads, only: %i[create update destroy]
end
