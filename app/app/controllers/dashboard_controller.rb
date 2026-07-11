class DashboardController < ApplicationController
  def show
    readable_requests = authorized_scope(
      "service_requests",
      "read",
      ServiceRequest.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    )

    @open_requests = readable_requests.where.not(status: %w[resolved canceled])
    @new_requests = readable_requests.where(status: "new")
    @urgent_requests = readable_requests.where(priority: "urgent").where.not(status: %w[resolved canceled])
    @recent_requests = readable_requests.order(reported_at: :desc).limit(8)
  end
end
