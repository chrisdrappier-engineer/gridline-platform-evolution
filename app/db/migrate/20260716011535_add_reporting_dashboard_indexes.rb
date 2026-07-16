class AddReportingDashboardIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :service_requests, %i[status reported_at], name: "index_service_requests_on_status_and_reported_at"
    add_index :service_requests, %i[customer_site_id status reported_at], name: "index_service_requests_on_site_status_reported"
    add_index :service_requests, %i[service_provider_id status reported_at], name: "index_service_requests_on_provider_status_reported"
    add_index :service_requests, %i[priority status], name: "index_service_requests_on_priority_and_status"
    add_index :service_requests, %i[follow_up_to_service_request_id reported_at], name: "index_service_requests_on_follow_up_and_reported"

    add_index :service_request_quotes, %i[status approval_required], name: "index_service_request_quotes_on_status_and_required"
    add_index :service_request_costs, %i[category incurred_on], name: "index_service_request_costs_on_category_and_incurred"
    add_index :service_request_feedbacks, %i[follow_up_needed rating], name: "index_service_request_feedbacks_on_follow_up_and_rating"
  end
end
