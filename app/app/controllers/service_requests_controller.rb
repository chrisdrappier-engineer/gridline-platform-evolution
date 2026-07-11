class ServiceRequestsController < ApplicationController
  before_action :set_service_request, only: %i[show triage]
  before_action :set_form_options, only: %i[new create]

  def index
    @service_requests = authorized_scope(
      "service_requests",
      "read",
      ServiceRequest.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
  end

  def show
    authorize!("service_requests", "read", @service_request)
  end

  def new
    @service_request = ServiceRequest.new(
      priority: "normal",
      customer_site: preselected_customer_site
    )
    authorize!("service_requests", "create", @service_request.customer_site) if @service_request.customer_site
  end

  def create
    customer_site = CustomerSite.find(service_request_params.fetch(:customer_site_id))
    authorize!("service_requests", "create", customer_site)

    @service_request = ServiceRequest.new(service_request_params)
    @service_request.created_by = current_user
    @service_request.status = "new"
    @service_request.reported_at = Time.current

    if @service_request.save
      redirect_to @service_request, notice: "Service request created."
    else
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

  private

  def set_service_request
    @service_request = ServiceRequest
                       .includes(:created_by, :assigned_dispatcher, :service_provider, customer_site: :customer)
                       .find(params[:id])
  end

  def set_form_options
    @customer_sites = authorized_scope(
      "service_requests",
      "create",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )
    @service_providers = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.where(status: "active").order(:name)
    )
  end

  def service_request_params
    params.require(:service_request).permit(:customer_site_id, :service_provider_id, :title, :description, :priority)
  end

  def preselected_customer_site
    return if params[:customer_site_id].blank?

    CustomerSite.includes(:customer).find_by(id: params[:customer_site_id])
  end
end
