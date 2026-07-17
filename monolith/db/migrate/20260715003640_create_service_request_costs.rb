class CreateServiceRequestCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_costs, id: :uuid do |t|
      t.references :service_request, null: false, foreign_key: true, type: :uuid
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :category, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.date :incurred_on, null: false
      t.text :description

      t.timestamps
    end

    add_index :service_request_costs, :category
    add_index :service_request_costs, :incurred_on
    add_index :service_request_costs, [:service_request_id, :incurred_on]
  end
end
