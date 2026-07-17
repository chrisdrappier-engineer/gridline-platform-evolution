class AddWorkflowDetailsToServiceRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :service_requests, :provider_response_summary, :text
    add_column :service_requests, :follow_up_notes, :text
    add_column :service_requests, :provider_work_completed_at, :datetime
    add_column :service_requests, :completion_verified_at, :datetime
    add_reference :service_requests, :completion_verified_by, type: :uuid, foreign_key: { to_table: :users }
  end
end
