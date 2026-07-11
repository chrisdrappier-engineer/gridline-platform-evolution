class CustomerSitesController < ApplicationController
  def show
    @customer_site = CustomerSite.includes(:customer, :created_by).find(params[:id])
    authorize!("customer_sites", "read", @customer_site)

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @customer_site.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end
end
