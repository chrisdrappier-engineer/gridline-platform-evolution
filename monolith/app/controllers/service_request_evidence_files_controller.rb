class ServiceRequestEvidenceFilesController < ApplicationController
  before_action :set_evidence_file

  def show
    authorize_evidence_file!

    redirect_to rails_blob_path(@evidence_file.file, disposition: "attachment"), allow_other_host: true
  end

  def thumbnail
    authorize_evidence_file!

    redirect_to rails_representation_path(
      @evidence_file.file.variant(resize_to_limit: [240, 160]).processed
    ), allow_other_host: true
  end

  private

  def set_evidence_file
    @evidence_file = ServiceRequestEvidenceFile
                     .includes(service_request_note: { service_request: [:service_provider, { customer_site: :customer }] })
                     .find(params[:id])
  end

  def authorize_evidence_file!
    note = @evidence_file.service_request_note
    authorize!("service_request_notes", "read", note)
    return if note.evidence_files_visible_to(current_user).exists?(id: @evidence_file.id)

    raise Authorization::AccessDenied
  end
end
