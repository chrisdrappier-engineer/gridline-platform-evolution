class ServiceRequestsController < ApplicationController
  before_action :set_service_request, only: %i[show edit update triage assign respond verify_completion]
  before_action :set_form_options, only: %i[new create]
  before_action :set_assign_options, only: %i[show assign]

  def index
    relation = authorized_scope(
      "service_requests",
      "read",
      ServiceRequest
        .left_joins(:assigned_dispatcher, :service_provider, customer_site: :customer)
        .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    )

    @filter_sites = authorized_scope(
      "customer_sites",
      "read",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )
    @filter_dispatchers = User
                          .where(id: relation.where.not(assigned_dispatcher_id: nil).select(:assigned_dispatcher_id))
                          .order(:name)

    @service_requests_table = ServiceRequestsTable.build(
      relation: relation,
      params: service_requests_table_params,
      path: service_requests_path,
      paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
    )
    @service_requests = @service_requests_table.rows
  end

  def show
    authorize!("service_requests", "read", @service_request)
    @quote = @service_request.service_request_quote || ServiceRequestQuote.new
    @service_request_cost = ServiceRequestCost.new(incurred_on: Date.current, currency: "USD")
    @service_request_page = ServiceRequestShowPage.new(
      service_request: @service_request,
      quote_form: @quote,
      cost_form: @service_request_cost,
      assignable_service_providers: @assignable_service_providers,
      view_context: view_context
    )
  end

  def edit
    authorize!("service_requests", "update", @service_request)
  end

  def update
    authorize!("service_requests", "update", @service_request)

    if @service_request.update(service_request_update_params)
      redirect_to @service_request, notice: "Service request updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    selected_site = @context_customer_site || (@customer_sites.first if @customer_sites.one?)

    @service_request = ServiceRequest.new(
      priority: "normal",
      customer_site: selected_site
    )
    set_form_page
  end

  def create
    customer_site = CustomerSite.find(service_request_params.fetch(:customer_site_id))
    authorize!("service_requests", "create", customer_site)

    @service_request = ServiceRequest.new(service_request_attributes)
    @service_request.service_provider = requested_service_provider || default_service_provider
    @service_request.created_by = current_user
    @service_request.status = "new"
    @service_request.reported_at = Time.current

    if @service_request.save
      redirect_to @service_request, notice: "Service request created."
    else
      set_form_page
      render :new, status: :unprocessable_entity
    end
  end

  def triage
    authorize!("service_requests", "triage", @service_request)

    @service_request.update!(
      status: "triaged",
      assigned_dispatcher: current_user
    )
    redirect_to @service_request, notice: "Service request triaged."
  end

  def assign
    authorize!("service_requests", "assign", @service_request)

    provider = authorized_scope("service_providers", "read", ServiceProvider.where(status: "active"))
               .find(assign_params.fetch(:service_provider_id))

    @service_request.update!(
      service_provider: provider,
      status: @service_request.status == "new" ? "triaged" : @service_request.status,
      assigned_dispatcher: @service_request.assigned_dispatcher || current_user
    )
    redirect_to @service_request, notice: "Service provider assigned."
  end

  def respond
    authorize!("service_requests", "respond", @service_request)

    attributes = response_params.to_h
    mark_complete = ActiveModel::Type::Boolean.new.cast(attributes.delete("mark_provider_work_complete"))
    now = Time.current
    attributes["provider_responded_at"] = @service_request.provider_responded_at || now
    attributes["status"] = "resolved" if mark_complete
    attributes["provider_work_completed_at"] = now if mark_complete

    @service_request.update!(attributes)
    redirect_to @service_request, notice: mark_complete ? "Provider work marked complete." : "Provider response recorded."
  end

  def verify_completion
    authorize!("service_requests", "verify_completion", @service_request)

    unless @service_request.status == "resolved"
      redirect_to @service_request, alert: "Only resolved requests can be verified."
      return
    end

    @service_request.update!(
      completion_verified_at: Time.current,
      completion_verified_by: current_user
    )
    redirect_to @service_request, notice: "Completion verified."
  end

  private

  def set_service_request
    @service_request = ServiceRequest
                       .includes(
                         :created_by,
                         :assigned_dispatcher,
                         :service_provider,
                         :service_request_quote,
                         service_request_costs: :recorded_by,
                         customer_site: :customer
                       )
                       .find(params[:id])
  end

  def set_form_options
    @context_customer_site = preselected_customer_site
    @context_customer = preselected_customer || @context_customer_site&.customer

    site_scope = authorized_scope(
      "service_requests",
      "create",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )

    if @context_customer_site
      authorize!("service_requests", "create", @context_customer_site)
      site_scope = site_scope.where(id: @context_customer_site.id)
    elsif @context_customer
      authorize!("customers", "read", @context_customer)
      site_scope = site_scope.where(customer_id: @context_customer.id)
    end

    @customer_sites = site_scope.to_a
    authorize!("service_requests", "create") if action_name == "new" && @customer_sites.empty?

    @service_providers = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.where(status: "active").order(:name)
    ).to_a
  end

  def set_form_page
    @service_request_form_page = ServiceRequestFormPage.new(
      service_request: @service_request,
      customer_sites: @customer_sites,
      service_providers: @service_providers,
      context_customer: @context_customer
    )
  end

  def set_assign_options
    @assignable_service_providers = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.where(status: "active").order(:name)
    )
  end

  def filtered_service_requests(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(customer_site_id: params[:customer_site_id]) if params[:customer_site_id].present?
    scope
  end

  def service_requests_table_params
    table_params = params.fetch(:service_requests, {}).permit(
      :search,
      :status,
      :priority,
      :customer_site_id,
      :dispatcher_id,
      :sort,
      :direction,
      :page,
      :limit
    ).to_h

    legacy_params = params.permit(:status, :priority, :customer_site_id).to_h
    legacy_params.merge(table_params)
  end

  def service_request_params
    params.require(:service_request).permit(:customer_site_id, :service_provider_id, :title, :description, :priority)
  end

  def service_request_attributes
    service_request_params.except(:service_provider_id)
  end

  def requested_service_provider
    return if service_request_params[:service_provider_id].blank?

    authorized_scope("service_providers", "read", ServiceProvider.where(status: "active"))
      .find(service_request_params[:service_provider_id])
  end

  def default_service_provider
    ServiceProvider.find_by!(name: "Gridline Internal Dispatch Team")
  end

  def assign_params
    params.require(:service_request).permit(:service_provider_id)
  end

  def response_params
    params
      .require(:service_request)
      .permit(:provider_response_summary, :follow_up_notes, :mark_provider_work_complete)
  end

  def service_request_update_params
    params.require(:service_request).permit(:title, :description, :priority, :status)
  end

  def preselected_customer_site
    return if params[:customer_site_id].blank?

    CustomerSite.includes(:customer).find(params[:customer_site_id])
  end

  def preselected_customer
    return if params[:customer_id].blank?

    Customer.find(params[:customer_id])
  end
end
