Rails.application.routes.draw do
  root "transactions#index"
  get  "/tx/clear",      to: "transactions#clear",  as: :clear_tx_details
  get "/tx/latest", to: "transactions#latest", as: :latest_transaction
  get  "/tx/:key",         to: "transactions#show", as: :transaction, constraints: { key: /(pi|ch|cs|in)_.+/ }
  post "/stripe/webhooks", to: "stripe/webhooks#receive"
  get "/exports/daily.csv", to: "exports#daily", as: :daily_export
  get  "/transactions/:key/export", to: "transactions#export",       as: :export_transaction, defaults: { format: :csv }
  get  "/transactions/export",      to: "transactions#export_index", as: :export_transactions, defaults: { format: :csv }

end
