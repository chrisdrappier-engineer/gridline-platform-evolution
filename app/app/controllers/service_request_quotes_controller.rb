class ServiceRequestQuotesController < ApplicationController
  before_action :set_service_request
  before_action :set_quote, only: %i[update approve reject]

  def create
    authorize!("service_request_quotes", "create", @service_request)

    @quote = @service_request.build_service_request_quote(
      quote_params.merge(created_by: current_user)
    )
    @quote.submit!(actor: current_user)

    redirect_to @service_request, notice: quote_notice, status: :see_other
  rescue ActiveRecord::RecordInvalid
    render_quote_error
  end

  def update
    authorize!("service_request_quotes", "update", @quote)

    @quote.amend!(quote_params, actor: current_user)
    redirect_to @service_request, notice: quote_notice(prefix: "Quote amended."), status: :see_other
  rescue ActiveRecord::RecordInvalid
    render_quote_error
  end

  def approve
    authorize!("service_request_quotes", "approve", @quote)

    @quote.approve!(actor: current_user, notes: decision_params[:approval_notes])
    redirect_to @service_request, notice: "Quote approved.", status: :see_other
  end

  def reject
    authorize!("service_request_quotes", "reject", @quote)

    @quote.reject!(actor: current_user, notes: decision_params[:approval_notes])
    redirect_to @service_request, notice: "Quote rejected.", status: :see_other
  end

  private

  def set_service_request
    @service_request = ServiceRequest
                       .includes(:service_request_quote, service_request_notes: :author, customer_site: :customer)
                       .find(params[:service_request_id])
  end

  def set_quote
    @quote = @service_request.service_request_quote
  end

  def quote_params
    params.require(:service_request_quote).permit(:amount_dollars, :description, :amendment_reason)
  end

  def decision_params
    params.fetch(:service_request_quote, {}).permit(:approval_notes)
  end

  def quote_notice(prefix: "Quote submitted.")
    return "#{prefix} Approval is required before work proceeds." if @quote.pending_approval?

    "#{prefix} Quote approved under the customer threshold."
  end

  def render_quote_error
    @service_request_cost = ServiceRequestCost.new(incurred_on: Date.current)
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
end
