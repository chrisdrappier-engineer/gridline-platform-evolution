class AddFollowUpToServiceRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_requests,
                  :follow_up_to_service_request,
                  null: true,
                  foreign_key: { to_table: :service_requests },
                  type: :uuid
  end
end
