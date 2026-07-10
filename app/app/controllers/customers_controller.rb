class CustomersController < ApplicationController
  def show
    @customer = Customer.includes(:created_by, :customer_sites).find(params[:id])
    @service_requests = ServiceRequest
                        .joins(:customer_site)
                        .where(customer_sites: { customer_id: @customer.id })
                        .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
                        .order(reported_at: :desc)
  end
end
