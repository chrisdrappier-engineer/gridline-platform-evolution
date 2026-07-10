class CreateServiceRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :service_requests, id: :uuid do |t|
      t.references :customer_site, null: false, type: :uuid, foreign_key: true
      t.references :service_provider, null: false, type: :uuid, foreign_key: true
      t.references :created_by, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :assigned_dispatcher, type: :uuid, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :priority, null: false
      t.string :status, null: false
      t.datetime :reported_at, null: false

      t.timestamps
    end

    add_index :service_requests, :priority
    add_index :service_requests, :status
    add_index :service_requests, :reported_at
  end
end
