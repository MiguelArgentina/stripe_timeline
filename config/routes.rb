Rails.application.routes.draw do
  root "transactions#index"

  resource  :session,       only: [:new, :create, :destroy]
  get  "/login",  to: "sessions#new"
  delete "/logout", to: "sessions#destroy"
  resource  :registration,  only: [:new, :create]
  resource  :settings,      only: [:edit, :update]

  get  "/tx/clear",      to: "transactions#clear",  as: :clear_tx_details
  get "/tx/latest", to: "transactions#latest", as: :latest_transaction
  get  "/tx/:key",         to: "transactions#show", as: :transaction, constraints: { key: /(pi|ch|cs|in)_.+/ }
  post "/stripe/webhooks", to: "stripe/webhooks#receive"
  get "/exports/daily.csv", to: "exports#daily", as: :daily_export
  get  "/transactions/:key/export",
       to: "exports#export",
       as: :export_transaction,
       defaults: { format: :csv }

  get  "/transactions/export",
       to: "exports#export_index",
       as: :export_transactions,
       defaults: { format: :csv }
end
