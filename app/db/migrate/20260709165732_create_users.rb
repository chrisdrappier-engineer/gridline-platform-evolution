class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto"

    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
