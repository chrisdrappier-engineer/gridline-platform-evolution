class ServiceRequestNotesController < ApplicationController
  before_action :set_service_request

  def create
    authorize!("service_request_notes", "create", @service_request)

    @note = @service_request.service_request_notes.build(note_params.merge(author: current_user))
    @note.save!

    redirect_to @service_request, notice: "Service request note added.", status: :see_other
  rescue ActiveRecord::RecordInvalid
    render_service_request_show
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
                         service_request_notes: :author,
                         customer_site: :customer
                       )
                       .find(params[:service_request_id])
  end

  def note_params
    params.require(:service_request_note).permit(:note_type, :visibility, :body)
  end

  def render_service_request_show
    @quote = @service_request.service_request_quote || ServiceRequestQuote.new
    @service_request_cost = ServiceRequestCost.new(incurred_on: Date.current, currency: "USD")
    @service_request_note = @note
    @assignable_service_providers = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.where(status: "active").order(:name)
    )
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
