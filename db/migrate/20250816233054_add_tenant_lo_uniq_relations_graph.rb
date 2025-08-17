# db/migrate/20250816233054_add_tenant_lo_uniq_relations_graph.rb
class AddTenantLoUniqRelationsGraph < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Drop the old unique index (without tenant) if present
    remove_index :stripe_relations,
                 name: :uniq_relations_graph,
                 algorithm: :concurrently,
                 if_exists: true

    # Recreate it including tenant_id
    add_index :stripe_relations,
              [:tenant_id, :from_type, :from_id, :to_type, :to_id, :relation, :account],
              unique: true,
              name: :uniq_relations_graph,
              algorithm: :concurrently
  end

  def down
    remove_index :stripe_relations,
                 name: :uniq_relations_graph,
                 algorithm: :concurrently,
                 if_exists: true

    add_index :stripe_relations,
              [:from_type, :from_id, :to_type, :to_id, :relation, :account],
              unique: true,
              name: :uniq_relations_graph,
              algorithm: :concurrently
  end
end
