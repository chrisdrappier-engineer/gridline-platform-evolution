class CreateServiceRequestFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_feedbacks, id: :uuid do |t|
      t.references :service_request, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :rating, null: false
      t.boolean :follow_up_needed, null: false, default: false
      t.text :feedback, null: false

      t.timestamps
    end
  end
end
