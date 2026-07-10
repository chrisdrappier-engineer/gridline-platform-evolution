class CustomerSitesController < ApplicationController
  def show
    @customer_site = CustomerSite.includes(:customer, :created_by).find(params[:id])
    @service_requests = @customer_site
                        .service_requests
                        .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
                        .order(reported_at: :desc)
  end
end
