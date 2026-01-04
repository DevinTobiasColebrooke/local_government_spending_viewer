Rails.application.routes.draw do
  namespace :admin do
      root to: "dashboard#index"
    end

  # Enable both index and show actions
  resources :spending_reports, only: [ :index, :show ]
  root "spending_reports#index"

  # Development-only route to trigger data ingestion via the UI
  if Rails.env.development?
    post "ingestion/fetch", to: "ingestion#fetch", as: :ingestion_fetch
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
