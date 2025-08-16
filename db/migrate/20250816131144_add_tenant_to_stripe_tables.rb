class AddTenantToStripeTables < ActiveRecord::Migration[8.0]
  def change
    # Add tenant references
    add_reference :stripe_events,           :tenant, null: false, foreign_key: true
    add_reference :stripe_objects,          :tenant, null: false, foreign_key: true
    add_reference :stripe_relations,        :tenant, null: false, foreign_key: true
    add_reference :transaction_summaries,   :tenant, null: false, foreign_key: true
    # :app_settings already has tenant:references if you generated it earlier; skip unless you didn’t.

    # Helpful indexes for multi-tenant lookups
    add_index :stripe_events,         [:tenant_id, :transaction_key, :created_at_unix], name: "idx_events_tenant_key_time"
    add_index :stripe_objects,        [:tenant_id, :object_type, :object_id], unique: true, name: "idx_objects_tenant_type_id"
    add_index :stripe_relations,      [:tenant_id, :from_type, :from_id, :to_type, :to_id, :relation], name: "idx_relations_tenant_multi"
    add_index :transaction_summaries, [:tenant_id, :last_event_at_unix], name: "idx_tx_summaries_tenant_time"
  end
end
