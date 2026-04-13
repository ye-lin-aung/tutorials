Tutorials::Engine.routes.draw do
  get "gallery", to: "tours#gallery", as: :gallery, defaults: { format: :html }

  resources :tours, only: [:index, :show], defaults: { format: :json }, constraints: { id: %r{[^/]+} }
  resource  :progress, only: [:update], controller: :progress, defaults: { format: :json }
end
