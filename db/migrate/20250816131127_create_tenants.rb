class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :primary_domain
      t.string :webhook_signing_secret

      t.timestamps
    end
    add_index :tenants, :primary_domain
  end
end
