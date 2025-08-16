class CreateTransactionSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_summaries do |t|
      t.string  :transaction_key, null: false
      t.string  :last_type
      t.integer :last_event_at_unix
      t.integer :amount_integer
      t.string  :currency
      t.string  :status
      t.string  :latest_pi
      t.string  :latest_charge
      t.string  :email
      t.boolean :livemode
      t.string  :account
      t.integer :events_count, default: 0, null: false
      t.timestamps
    end
    add_index :transaction_summaries, :transaction_key, unique: true
  end
end
