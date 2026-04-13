Tutorials::Engine.routes.draw do
  resources :tours, only: [:index, :show], defaults: { format: :json }, constraints: { id: %r{[^/]+} }
  resource  :progress, only: [:update], controller: :progress, defaults: { format: :json }
end
