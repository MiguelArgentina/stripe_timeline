class CreateDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :domains do |t|
      t.string :host
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
    add_index :domains, :host
  end
end
