class CreateStripeRelations < ActiveRecord::Migration[8.0]
  def change
    create_table :stripe_relations do |t|
      t.string :from_type
      t.string :from_id
      t.string :to_type
      t.string :to_id
      t.string :relation
      t.string :account

      t.timestamps
    end
  end
end
