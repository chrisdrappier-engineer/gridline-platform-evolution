class ServiceRequestsController < ApplicationController
  before_action :set_service_request, only: %i[show triage]
  before_action :set_form_options, only: %i[new create]

  def index
    @service_requests = ServiceRequest
                        .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
                        .order(reported_at: :desc)
  end

  def show
  end

  def new
    @service_request = ServiceRequest.new(
      priority: "normal",
      customer_site: preselected_customer_site
    )
  end

  def create
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
    @customer_sites = CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    @service_providers = ServiceProvider.where(status: "active").order(:name)
  end

  def service_request_params
    params.require(:service_request).permit(:customer_site_id, :service_provider_id, :title, :description, :priority)
  end

  def preselected_customer_site
    return if params[:customer_site_id].blank?

    CustomerSite.includes(:customer).find_by(id: params[:customer_site_id])
  end
end
