class CreateServiceRequestNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_notes, id: :uuid do |t|
      t.references :service_request, null: false, foreign_key: true, type: :uuid
      t.references :author, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :note_type, null: false
      t.string :visibility, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :service_request_notes, :note_type
    add_index :service_request_notes, :visibility
    add_index :service_request_notes, [:service_request_id, :created_at]
  end
end
