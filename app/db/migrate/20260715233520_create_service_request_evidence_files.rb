class CreateServiceRequestEvidenceFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_evidence_files, id: :uuid do |t|
      t.references :service_request_note, null: false, foreign_key: true, type: :uuid
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :category, null: false

      t.timestamps
    end

    add_index :service_request_evidence_files, :category
    add_index :service_request_evidence_files, [:service_request_note_id, :created_at]
  end
end
