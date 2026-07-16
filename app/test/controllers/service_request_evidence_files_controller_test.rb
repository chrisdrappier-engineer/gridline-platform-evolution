require "test_helper"

class ServiceRequestEvidenceFilesControllerTest < ActionDispatch::IntegrationTest
  test "authorized user can download evidence file" do
    evidence_file = create_evidence_file!(
      note: service_request_notes(:two),
      category: "diagnostic_report",
      uploaded_by: users(:five),
      filename: "diagnostic-report.txt",
      content_type: "text/plain"
    )

    sign_in_as users(:five)
    get service_request_evidence_file_path(evidence_file)

    assert_response :redirect
  end

  test "user who cannot see note cannot access evidence file" do
    evidence_file = create_evidence_file!(
      note: service_request_notes(:two),
      category: "diagnostic_report",
      uploaded_by: users(:five),
      filename: "diagnostic-report.txt",
      content_type: "text/plain"
    )

    sign_in_as users(:three)
    get service_request_evidence_file_path(evidence_file)

    assert_redirected_to dashboard_path
  end

  private

  def create_evidence_file!(note:, category:, uploaded_by:, filename:, content_type:)
    evidence_file = ServiceRequestEvidenceFile.new(
      service_request_note: note,
      category: category,
      uploaded_by: uploaded_by
    )
    File.open(Rails.root.join("db/demo_files/#{filename}"), "rb") do |file|
      evidence_file.file.attach(io: file, filename: filename, content_type: content_type)
      evidence_file.save!
    end
    evidence_file
  end
end
