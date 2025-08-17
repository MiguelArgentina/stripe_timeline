# db/migrate/20240816_adjust_unique_index_on_stripe_objects.rb
class AdjustUniqueIndexOnStripeObjects < ActiveRecord::Migration[7.1]
  def change
    remove_index :stripe_objects, name: :uniq_object_snapshot, if_exists: true
    add_index :stripe_objects, [:tenant_id, :object_type, :object_id],
              unique: true, name: :uniq_object_snapshot
  end
end
