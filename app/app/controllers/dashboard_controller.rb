class DashboardController < ApplicationController
  def show
    @open_requests = ServiceRequest.where.not(status: %w[resolved canceled])
    @new_requests = ServiceRequest.where(status: "new")
    @urgent_requests = ServiceRequest.where(priority: "urgent").where.not(status: %w[resolved canceled])
    @recent_requests = ServiceRequest
                       .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
                       .order(reported_at: :desc)
                       .limit(8)
  end
end
