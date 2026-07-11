class ServiceProvidersController < ApplicationController
  def show
    @service_provider = ServiceProvider.includes(:created_by).find(params[:id])
    authorize!("service_providers", "read", @service_provider)

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @service_provider.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end
end
