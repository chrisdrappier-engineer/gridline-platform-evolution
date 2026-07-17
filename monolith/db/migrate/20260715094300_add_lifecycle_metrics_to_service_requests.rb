class AddLifecycleMetricsToServiceRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :service_requests, :assigned_at, :datetime
    add_column :service_requests, :provider_responded_at, :datetime
    add_column :service_requests, :scheduled_at, :datetime
    add_column :service_requests, :resolved_at, :datetime
    add_column :service_requests, :canceled_at, :datetime
    add_column :service_requests, :provider_response_seconds, :integer
    add_column :service_requests, :provider_completion_seconds, :integer
    add_column :service_requests, :resolution_seconds, :integer
    add_column :service_requests, :verification_lag_seconds, :integer

    add_index :service_requests, :assigned_at
    add_index :service_requests, :provider_responded_at
    add_index :service_requests, :resolved_at
    add_index :service_requests, :provider_response_seconds
    add_index :service_requests, :provider_completion_seconds
  end
end
