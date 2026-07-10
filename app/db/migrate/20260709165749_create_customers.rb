class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :name, null: false
      t.string :account_status, null: false
      t.string :industry
      t.references :created_by, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :customers, :account_status
  end
end
