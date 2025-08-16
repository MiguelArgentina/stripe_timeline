class CreateAppSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :app_settings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.boolean :fetch_fees
      t.string :stripe_api_key

      t.timestamps
    end
  end
end
