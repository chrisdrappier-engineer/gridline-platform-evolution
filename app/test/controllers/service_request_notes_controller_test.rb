require "test_helper"

class ServiceRequestNotesControllerTest < ActionDispatch::IntegrationTest
  DEMO_FILES = Rails.root.join("db/demo_files")

  test "dispatcher creates internal note" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_difference "ServiceRequestNote.count", 1 do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: {
          note_type: "intake",
          visibility: "internal",
          body: "Caller reports intermittent lobby fan cycling."
        }
      }
    end

    assert_redirected_to service_request_path(request)
    note = request.service_request_notes.order(:created_at).last
    assert_equal users(:one), note.author
    assert_equal "internal", note.visibility
  end

  test "dispatcher uploads allowed evidence files with note" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_difference "ServiceRequestEvidenceFile.count", 4 do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: {
          note_type: "intake",
          visibility: "internal",
          body: "Evidence files received during intake.",
          evidence_category: "site_photo",
          evidence_files: [
            upload("before-photo.png", "image/png"),
            upload("invoice-sample.pdf", "application/pdf"),
            upload("diagnostic-report.txt", "text/plain"),
            upload("sensor-log.csv", "text/csv")
          ]
        }
      }
    end

    assert_redirected_to service_request_path(request)
    assert ServiceRequestEvidenceFile.order(:created_at).last.file.attached?
  end

  test "video upload is rejected" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestEvidenceFile.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: evidence_params(
          evidence_files: [temp_upload("evidence.mp4", "video/mp4", "fake video")]
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /File type is not allowed/
  end

  test "office document upload is rejected" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestEvidenceFile.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: evidence_params(
          evidence_files: [temp_upload("evidence.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "fake docx")]
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /File type is not allowed/
  end

  test "oversized text upload is rejected with recovery instruction" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestEvidenceFile.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: evidence_params(
          evidence_files: [temp_upload("large.txt", "text/plain", "a" * (ServiceRequestEvidenceFile::MAX_TEXT_SIZE + 1))]
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /Text and CSV files must be 1 MB or smaller/
  end

  test "too many files on one note is rejected" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestEvidenceFile.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: evidence_params(
          evidence_files: 6.times.map { |index| temp_upload("evidence-#{index}.txt", "text/plain", "small") }
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /Each note can include up to 5 files/
  end

  test "facility manager creates customer visible note" do
    sign_in_as users(:three)
    request = service_requests(:one)

    assert_difference "ServiceRequestNote.count", 1 do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: {
          note_type: "customer_update",
          visibility: "customer_visible",
          body: "The east entrance will be open for technician access."
        }
      }
    end

    assert_redirected_to service_request_path(request)
  end

  test "facility manager cannot create internal note" do
    sign_in_as users(:three)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestNote.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: {
          note_type: "general",
          visibility: "internal",
          body: "This should not be accepted."
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /Visibility is not available for this user/
  end

  test "provider user cannot add note to unrelated provider request" do
    sign_in_as users(:five)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestNote.count" do
      post service_request_service_request_notes_path(request), params: {
        service_request_note: {
          note_type: "provider_update",
          visibility: "provider_visible",
          body: "Unauthorized provider update."
        }
      }
    end

    assert_redirected_to dashboard_path
  end

  private

  def evidence_params(evidence_files:)
    {
      note_type: "intake",
      visibility: "internal",
      body: "Evidence upload boundary test.",
      evidence_category: "site_photo",
      evidence_files: evidence_files
    }
  end

  def upload(filename, content_type)
    Rack::Test::UploadedFile.new(DEMO_FILES.join(filename), content_type)
  end

  def temp_upload(filename, content_type, content)
    file = Tempfile.new([File.basename(filename, ".*"), File.extname(filename)])
    file.binmode
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end
end
