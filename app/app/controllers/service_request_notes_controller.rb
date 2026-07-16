class ServiceRequestNotesController < ApplicationController
  before_action :set_service_request

  def create
    authorize!("service_request_notes", "create", @service_request)

    @note = @service_request.service_request_notes.build(note_attributes.merge(author: current_user))
    attach_evidence_files!

    redirect_to @service_request, notice: "Service request note added.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    copy_evidence_errors(error.record)
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
                         :service_request_feedback,
                         service_request_costs: :recorded_by,
                         service_request_notes: [:author, { service_request_evidence_files: [:uploaded_by, { file_attachment: :blob }] }],
                         customer_site: :customer
                       )
                       .find(params[:service_request_id])
  end

  def note_params
    params.require(:service_request_note).permit(:note_type, :visibility, :body, :evidence_category, evidence_files: [])
  end

  def note_attributes
    note_params.except(:evidence_category, :evidence_files)
  end

  def attach_evidence_files!
    uploads = evidence_uploads
    @note.errors.add(:base, "Each note can include up to 5 files. Add another note if you need to upload more evidence.") if uploads.count > ServiceRequestEvidenceFile::MAX_FILES_PER_NOTE
    @note.errors.add(:base, "Each note can include up to 15 MB of files. Add another note or reduce file sizes before uploading.") if evidence_upload_total(uploads) > ServiceRequestEvidenceFile::MAX_TOTAL_BYTES_PER_NOTE
    @note.errors.add(:base, "Choose an evidence category before uploading files.") if uploads.any? && note_params[:evidence_category].blank?
    raise ActiveRecord::RecordInvalid, @note if @note.errors.any?

    ServiceRequestNote.transaction do
      @note.save!
      uploads.each { |upload| create_evidence_file!(upload) }
    end
  end

  def evidence_uploads
    Array(note_params[:evidence_files]).compact_blank
  end

  def evidence_upload_total(uploads)
    uploads.sum(&:size)
  end

  def create_evidence_file!(upload)
    evidence_file = @note.service_request_evidence_files.build(
      category: note_params[:evidence_category],
      uploaded_by: current_user
    )
    evidence_file.file.attach(upload)
    evidence_file.save!
  rescue ActiveRecord::RecordInvalid => error
    copy_evidence_errors(error.record)
    raise ActiveRecord::RecordInvalid, @note
  end

  def copy_evidence_errors(record)
    return if record == @note || record.blank?

    record.errors.full_messages.each { |message| @note.errors.add(:base, message) }
  end

  def render_service_request_show
    @quote = @service_request.service_request_quote || ServiceRequestQuote.new
    @service_request_cost = ServiceRequestCost.new(incurred_on: Date.current, currency: "USD")
    @service_request_note = @note
    @service_request_feedback = @service_request.service_request_feedback || ServiceRequestFeedback.new(follow_up_needed: false)
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
      feedback_form: @service_request_feedback,
      assignable_service_providers: @assignable_service_providers,
      view_context: view_context
    )

    render "service_requests/show", status: :unprocessable_entity
  end
end
