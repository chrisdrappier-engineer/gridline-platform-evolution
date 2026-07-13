class CustomersController < ApplicationController
  def index
    relation = authorized_scope(
      "customers",
      "read",
      Customer.left_joins(:created_by).includes(:created_by)
    )

    @customers_table = CustomersTable.build(
      relation: relation,
      params: customers_table_params,
      path: customers_path,
      paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
    )
    @customers = @customers_table.rows
  end

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

  private

  def customers_table_params
    params.fetch(:customers, {}).permit(:search, :account_status, :sort, :direction, :page, :limit).to_h
  end
end
