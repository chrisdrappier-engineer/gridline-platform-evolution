class CreateServiceProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :service_providers do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :status, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :service_providers, :provider_type
    add_index :service_providers, :status
  end
end
