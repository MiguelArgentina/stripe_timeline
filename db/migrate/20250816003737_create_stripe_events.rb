class CreateStripeEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :stripe_events do |t|
      t.string :stripe_id
      t.string :type_name
      t.string :api_version
      t.string :account
      t.boolean :livemode
      t.integer :created_at_unix
      t.string :source
      t.string :transaction_key
      t.jsonb :payload

      t.timestamps
    end
  end
end
