class CustomersController < ApplicationController
  def show
    @customer = Customer.includes(:created_by, :customer_sites).find(params[:id])
    authorize!("customers", "read", @customer)

    @customer_sites = authorized_scope(
      "customer_sites",
      "read",
      @customer.customer_sites.order(:name)
    )
    @service_requests = authorized_scope(
      "service_requests",
      "read",
      ServiceRequest
        .joins(:customer_site)
        .where(customer_sites: { customer_id: @customer.id })
        .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end
end
