class CreateServiceRequestQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_quotes, id: :uuid do |t|
      t.references :service_request, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.text :description, null: false
      t.string :status, null: false, default: "draft"
      t.boolean :approval_required, null: false, default: false
      t.datetime :submitted_at
      t.references :approved_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :approved_at
      t.references :rejected_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :rejected_at
      t.text :approval_notes
      t.text :amendment_reason
      t.references :amended_by, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :amended_at
      t.integer :original_amount_cents

      t.timestamps
    end

    add_index :service_request_quotes, :status
    add_index :service_request_quotes, :approval_required
  end
end
