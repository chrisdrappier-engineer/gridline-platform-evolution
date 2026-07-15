class ServiceRequestCostsController < ApplicationController
  before_action :set_service_request
  before_action :set_cost, only: %i[edit update]

  def create
    authorize!("service_request_costs", "create", @service_request)

    @cost = @service_request.service_request_costs.build(
      cost_params.merge(recorded_by: current_user)
    )
    @cost.save!

    redirect_to @service_request, notice: "Service cost recorded.", status: :see_other
  rescue ActiveRecord::RecordInvalid
    @quote = @service_request.service_request_quote || ServiceRequestQuote.new
    @service_request_cost = @cost
    @assignable_service_providers = ServiceProvider.where(status: "active").order(:name)
    render "service_requests/show", status: :unprocessable_entity
  end

  def edit
    authorize!("service_request_costs", "update", @cost)
  end

  def update
    authorize!("service_request_costs", "update", @cost)

    if @cost.update(cost_params)
      redirect_to @service_request, notice: "Service cost updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_service_request
    @service_request = ServiceRequest.includes(customer_site: :customer).find(params[:service_request_id])
  end

  def set_cost
    @cost = @service_request.service_request_costs.find(params[:id])
  end

  def cost_params
    params.require(:service_request_cost).permit(:category, :amount_dollars, :currency, :incurred_on, :description)
  end
end
