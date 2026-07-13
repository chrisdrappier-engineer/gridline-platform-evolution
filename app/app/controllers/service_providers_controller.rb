class ServiceProvidersController < ApplicationController
  def index
    relation = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.left_joins(:created_by).includes(:created_by)
    )

    @service_providers_table = ServiceProvidersTable.build(
      relation: relation,
      params: service_providers_table_params,
      path: service_providers_path,
      paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
    )
    @service_providers = @service_providers_table.rows
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

  private

  def service_providers_table_params
    params.fetch(:service_providers, {}).permit(:search, :provider_type, :status, :sort, :direction, :page, :limit).to_h
  end
end
