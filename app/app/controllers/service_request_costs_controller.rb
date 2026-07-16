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
    @service_request_note = ServiceRequestNote.new(
      note_type: "general",
      visibility: ServiceRequestNote.default_visibility_for(current_user)
    )
    @assignable_service_providers = ServiceProvider.where(status: "active").order(:name)
    @service_request_page = ServiceRequestShowPage.new(
      service_request: @service_request,
      quote_form: @quote,
      cost_form: @service_request_cost,
      note_form: @service_request_note,
      assignable_service_providers: @assignable_service_providers,
      view_context: view_context
    )
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
    @service_request = ServiceRequest
                       .includes(
                         :service_request_quote,
                         service_request_notes: [:author, { service_request_evidence_files: [:uploaded_by, { file_attachment: :blob }] }],
                         customer_site: :customer
                       )
                       .find(params[:service_request_id])
  end

  def set_cost
    @cost = @service_request.service_request_costs.find(params[:id])
  end

  def cost_params
    params.require(:service_request_cost).permit(:category, :amount_dollars, :currency, :incurred_on, :description)
  end
end
