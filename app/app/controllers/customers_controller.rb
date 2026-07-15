class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update]

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

  def new
    authorize!("customers", "create")
    @customer = Customer.new(account_status: "onboarding", quote_approval_threshold_cents: 50_000)
  end

  def create
    authorize!("customers", "create")

    @customer = Customer.new(customer_params)
    @customer.created_by = current_user

    if @customer.save
      redirect_to @customer, notice: "Customer created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize!("customers", "update", @customer)
  end

  def update
    authorize!("customers", "update", @customer)

    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer
    @customer = Customer.includes(:created_by, :customer_sites).find(params[:id])
  end

  def customers_table_params
    params.fetch(:customers, {}).permit(:search, :account_status, :sort, :direction, :page, :limit).to_h
  end

  def customer_params
    params.require(:customer).permit(:name, :account_status, :industry, :quote_approval_threshold_cents)
  end
end
