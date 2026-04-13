Tutorials::Engine.routes.draw do
  resources :tours, only: [:index, :show], defaults: { format: :json }, constraints: { id: %r{[^/]+} }
  resource  :progress, only: [:update], defaults: { format: :json }
end
