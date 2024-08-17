Rails.application.routes.draw do
  root "hello#index"
  
  post 'vectors/create', to: 'vectors#create'
  get 'vectors/search', to: 'vectors#search'
end
