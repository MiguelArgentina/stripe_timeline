# db/migrate/20250816190000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string  :email, null: false
      t.string  :password_digest, null: false
      t.string  :role, null: false, default: "owner" # owner, admin, member (future)
      t.timestamps
    end
    add_index :users, [:tenant_id, :email], unique: true
  end
end
