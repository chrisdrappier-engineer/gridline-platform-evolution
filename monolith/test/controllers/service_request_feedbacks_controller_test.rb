require "test_helper"

class ServiceRequestFeedbacksControllerTest < ActionDispatch::IntegrationTest
  test "facility manager submits feedback for resolved assigned request" do
    sign_in_as users(:three)
    request = resolved_request(customer_site: customer_sites(:one))

    post service_request_service_request_feedback_path(request), params: {
      service_request_feedback: {
        rating: 5,
        feedback: "Work was completed cleanly and the site is operating normally.",
        follow_up_needed: "0"
      }
    }

    assert_redirected_to service_request_path(request)
    feedback = request.reload.service_request_feedback
    assert_equal 5, feedback.rating
    assert_equal users(:three), feedback.submitted_by
    assert_not feedback.follow_up_needed?
  end

  test "facility manager flags follow up needed" do
    sign_in_as users(:three)
    request = resolved_request(customer_site: customer_sites(:one))

    post service_request_service_request_feedback_path(request), params: {
      service_request_feedback: {
        rating: 3,
        feedback: "Main repair is complete, but access panel follow-up is needed.",
        follow_up_needed: "1"
      }
    }

    assert_redirected_to service_request_path(request)
    assert request.reload.service_request_feedback.follow_up_needed?
  end

  test "facility manager updates existing feedback" do
    sign_in_as users(:three)
    request = resolved_request(customer_site: customer_sites(:one))
    request.create_service_request_feedback!(
      submitted_by: users(:three),
      rating: 4,
      follow_up_needed: false,
      feedback: "Initial feedback."
    )

    patch service_request_service_request_feedback_path(request), params: {
      service_request_feedback: {
        rating: 2,
        feedback: "Follow-up is now needed after additional review.",
        follow_up_needed: "1"
      }
    }

    assert_redirected_to service_request_path(request)
    feedback = request.reload.service_request_feedback
    assert_equal 2, feedback.rating
    assert feedback.follow_up_needed?
  end

  test "rejects feedback before request is resolved" do
    sign_in_as users(:three)
    request = ServiceRequest.create!(
      customer_site: customer_sites(:one),
      service_provider: service_providers(:one),
      created_by: users(:one),
      title: "Unresolved feedback request #{SecureRandom.hex(4)}",
      description: "Unresolved request for feedback rejection coverage.",
      priority: "normal",
      status: "new",
      reported_at: Time.current
    )

    post service_request_service_request_feedback_path(request), params: {
      service_request_feedback: {
        rating: 5,
        feedback: "Too early.",
        follow_up_needed: "0"
      }
    }

    assert_redirected_to service_request_path(request)
    assert_nil request.reload.service_request_feedback
  end

  test "rejects feedback outside facility manager assignment scope" do
    sign_in_as users(:three)
    request = resolved_request(customer_site: customer_sites(:two))

    post service_request_service_request_feedback_path(request), params: {
      service_request_feedback: {
        rating: 5,
        feedback: "Should not save.",
        follow_up_needed: "0"
      }
    }

    assert_redirected_to dashboard_path
    assert_nil request.reload.service_request_feedback
  end

  private

  def resolved_request(customer_site:)
    ServiceRequest.create!(
      customer_site: customer_site,
      service_provider: service_providers(:one),
      created_by: users(:one),
      title: "Resolved feedback request #{SecureRandom.hex(4)}",
      description: "Resolved request for feedback coverage.",
      priority: "normal",
      status: "resolved",
      reported_at: 2.days.ago,
      assigned_at: 2.days.ago + 30.minutes,
      provider_responded_at: 2.days.ago + 1.hour,
      provider_work_completed_at: 1.day.ago,
      resolved_at: 1.day.ago + 30.minutes
    )
  end
end
