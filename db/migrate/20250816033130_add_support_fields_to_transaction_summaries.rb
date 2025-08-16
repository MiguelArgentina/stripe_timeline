class AddSupportFieldsToTransactionSummaries < ActiveRecord::Migration[8.0]
  def change
    add_column :transaction_summaries, :last4, :string
    add_column :transaction_summaries, :order_id, :string
    add_column :transaction_summaries, :customer_id, :string
  end
end
