class ServiceProvidersController < ApplicationController
  def index
    @service_providers = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.includes(:created_by).order(:name)
    )
  end

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
