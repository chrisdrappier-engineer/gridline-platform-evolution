class CustomerSitesController < ApplicationController
  before_action :set_customer_site, only: %i[show edit update]
  before_action :set_customer_options, only: %i[new create edit update]

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
    authorize!("customer_sites", "read", @customer_site)

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @customer_site.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end

  def new
    authorize!("customer_sites", "create")
    @customer_site = CustomerSite.new(
      customer_id: params[:customer_id],
      site_status: "active"
    )
  end

  def create
    authorize!("customer_sites", "create")

    @customer_site = CustomerSite.new(customer_site_params)
    @customer_site.created_by = current_user

    if @customer_site.save
      redirect_to @customer_site, notice: "Site created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize!("customer_sites", "update", @customer_site)
  end

  def update
    authorize!("customer_sites", "update", @customer_site)

    if @customer_site.update(customer_site_params)
      redirect_to @customer_site, notice: "Site updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer_site
    @customer_site = CustomerSite.includes(:customer, :created_by).find(params[:id])
  end

  def set_customer_options
    @customer_options = authorized_scope("customers", "read", Customer.order(:name))
  end

  def customer_sites_table_params
    params.fetch(:customer_sites, {}).permit(:search, :site_status, :sort, :direction, :page, :limit).to_h
  end

  def customer_site_params
    params.require(:customer_site).permit(
      :customer_id,
      :name,
      :address_line_1,
      :address_line_2,
      :city,
      :state,
      :postal_code,
      :site_status
    )
  end
end
