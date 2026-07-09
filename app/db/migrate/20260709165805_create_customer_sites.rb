class CreateCustomerSites < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_sites do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :site_status, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :customer_sites, :site_status
  end
end
