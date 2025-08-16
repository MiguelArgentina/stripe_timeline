class CreateStripeObjects < ActiveRecord::Migration[8.0]
  def change
    create_table :stripe_objects do |t|
      t.string :object_type
      t.string :object_id
      t.string :account
      t.jsonb :current
      t.string :last_event_id

      t.timestamps
    end
  end
end
