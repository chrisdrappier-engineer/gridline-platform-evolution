class CustomerSitesController < ApplicationController
  before_action :set_customer_site, only: %i[show edit update]
  before_action :set_customer_options, only: %i[new create edit update]
  before_action :set_facility_manager_options, only: %i[new create edit update]

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
    @page_actions = [
      ViewAction.link("View Requests", service_requests_path),
      new_site_action
    ].compact
    @site_row_actions = @customer_sites.index_with do |site|
      [
        create_request_for_site_action(site),
        edit_site_action(site)
      ].compact
    end
  end

  def show
    authorize!("customer_sites", "read", @customer_site)
    @page_actions = [
      ViewAction.link("Back to Sites", customer_sites_path),
      edit_site_action(@customer_site)
    ].compact

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @customer_site.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
    @service_request_actions = [
      create_request_for_site_action(@customer_site)
    ].compact
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

    if save_customer_site(@customer_site)
      redirect_to @customer_site, notice: "Site created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize!("customer_sites", "update", @customer_site)
    @customer_site.facility_manager_id = @customer_site.facility_managers.order(:name).first&.id
  end

  def update
    authorize!("customer_sites", "update", @customer_site)
    @customer_site.assign_attributes(customer_site_params)

    if save_customer_site(@customer_site)
      redirect_to @customer_site, notice: "Site updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_customer_site
    @customer_site = CustomerSite.includes(:customer, :created_by, :facility_managers).find(params[:id])
  end

  def set_customer_options
    @customer_options = authorized_scope("customers", "read", Customer.order(:name))
  end

  def set_facility_manager_options
    @facility_manager_options = User.where(active: true, role: "facility_manager").order(:name)
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
      :site_status,
      :facility_manager_id
    )
  end

  def new_site_action
    return unless permitted?("customer_sites", "create")

    ViewAction.link("New Site", new_customer_site_path, style: "primary-button")
  end

  def create_request_for_site_action(site)
    return unless can?("service_requests", "create", site)

    ViewAction.link("Create Service Request", new_service_request_path(customer_site_id: site.id), style: "table-link")
  end

  def edit_site_action(site)
    return unless can?("customer_sites", "update", site)

    ViewAction.link("Edit", edit_customer_site_path(site), style: "table-link")
  end

  def save_customer_site(customer_site)
    CustomerSite.transaction do
      return false unless customer_site.save

      assign_facility_manager(customer_site)
    end

    true
  end

  def assign_facility_manager(customer_site)
    return if customer_site.facility_manager_id.blank?

    role = Role.find_by!(key: "facility_manager")
    UserRoleAssignment.find_or_create_by!(
      user_id: customer_site.facility_manager_id,
      role: role,
      resource: customer_site
    )
  end
end
