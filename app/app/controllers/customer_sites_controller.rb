class CustomerSitesController < ApplicationController
  def index
    relation = authorized_scope(
      "customer_sites",
      "read",
      CustomerSite.left_joins(:customer).includes(:customer, :created_by)
    )

    @customer_sites_table = CustomerSitesTable.build(
      relation: relation,
      params: customer_sites_table_params,
      path: customer_sites_path,
      paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
    )
    @customer_sites = @customer_sites_table.rows
  end

  def show
    @customer_site = CustomerSite.includes(:customer, :created_by).find(params[:id])
    authorize!("customer_sites", "read", @customer_site)

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @customer_site.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end

  private

  def customer_sites_table_params
    params.fetch(:customer_sites, {}).permit(:search, :site_status, :sort, :direction, :page, :limit).to_h
  end
end
