require "test_helper"

class ServiceRequestNotesControllerTest < ActionDispatch::IntegrationTest
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
end
