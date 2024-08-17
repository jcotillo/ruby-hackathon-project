Rails.application.routes.draw do
  root "hello#index"
  
  post 'vectors/create', to: 'vectors#create'
  post 'vectors/search', to: 'vectors#search'
end
