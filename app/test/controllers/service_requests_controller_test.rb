require "test_helper"

class ServiceRequestsControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get service_requests_path

    assert_redirected_to login_path
  end

  test "shows service request queue" do
    sign_in_as users(:one)

    get service_requests_path

    assert_response :success
    assert_select "h1", "Service Requests"
    assert_select "a", text: service_requests(:one).title
    assert_select "a[href='#{service_provider_path(service_providers(:one))}']", text: service_providers(:one).name
    assert_select "a[href='#{customer_path(customers(:one))}']", text: customers(:one).name
    assert_select "a[href='#{customer_site_path(customer_sites(:one))}']", text: customer_sites(:one).name
    assert_select "a[href='#{dispatcher_path(users(:two))}']", text: users(:two).name
    assert_select ".status-new", text: "New"
  end

  test "service request queue only shows readable scoped rows" do
    sign_in_as users(:three)

    get service_requests_path

    assert_response :success
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }
  end

  test "service request queue can be filtered by status priority and site" do
    sign_in_as users(:one)

    get service_requests_path(
      status: service_requests(:one).status,
      priority: service_requests(:one).priority,
      customer_site_id: customer_sites(:one).id
    )

    assert_response :success
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }
  end

  test "shows new service request form" do
    sign_in_as users(:one)

    get new_service_request_path

    assert_response :success
    assert_select "h1", "New Service Request"
    assert_select "select[name='service_request[customer_site_id]']"
    assert_select "select[name='service_request[service_provider_id]']"
  end

  test "prefills site context when launched from a site page" do
    sign_in_as users(:one)

    get new_service_request_path(customer_site_id: customer_sites(:one).id)

    assert_response :success
    assert_select ".context-panel", text: /#{customer_sites(:one).name}/
    assert_select "input[type='hidden'][name='service_request[customer_site_id]'][value='#{customer_sites(:one).id}']"
    assert_select "select[name='service_request[customer_site_id]']", count: 0
  end

  test "locks site choice when customer context has one authorized site" do
    sign_in_as users(:one)

    get new_service_request_path(customer_id: customers(:one).id)

    assert_response :success
    assert_select ".context-panel", text: /#{customer_sites(:one).name}/
    assert_select "input[type='hidden'][name='service_request[customer_site_id]'][value='#{customer_sites(:one).id}']"
    assert_select "select[name='service_request[customer_site_id]']", count: 0
    assert_select "select[name='service_request[customer_site_id]'] option[value='#{customer_sites(:two).id}']", count: 0
  end

  test "rejects new request form for unauthorized customer context" do
    sign_in_as users(:three)

    get new_service_request_path(customer_id: customers(:two).id)

    assert_redirected_to dashboard_path
  end

  test "rejects new request form for unauthorized preselected site" do
    sign_in_as users(:three)

    get new_service_request_path(customer_site_id: customer_sites(:two).id)

    assert_redirected_to dashboard_path
  end

  test "shows service request detail" do
    sign_in_as users(:one)

    get service_request_path(service_requests(:one))

    assert_response :success
    assert_select "h1", service_requests(:one).title
    assert_select "form[action='#{triage_service_request_path(service_requests(:one))}']"
  end

  test "rejects unreadable service request detail" do
    sign_in_as users(:three)

    get service_request_path(service_requests(:two))

    assert_redirected_to dashboard_path
  end

  test "creates service request" do
    sign_in_as users(:one)

    assert_difference "ServiceRequest.count", 1 do
      post service_requests_path, params: {
        service_request: {
          customer_site_id: customer_sites(:one).id,
          service_provider_id: service_providers(:one).id,
          title: "Generator alarm",
          description: "Backup generator reports a warning state.",
          priority: "high"
        }
      }
    end

    request = ServiceRequest.order(:created_at).last
    assert_redirected_to service_request_path(request)
    assert_equal users(:one), request.created_by
    assert_equal "new", request.status
  end

  test "facility manager creates request for managed facility with dispatch default provider" do
    sign_in_as users(:three)

    assert_difference "ServiceRequest.count", 1 do
      post service_requests_path, params: {
        service_request: {
          customer_site_id: customer_sites(:one).id,
          title: "Tenant entry light outage",
          description: "Entry light is out near the main lobby.",
          priority: "normal"
        }
      }
    end

    request = ServiceRequest.order(:created_at).last
    assert_redirected_to service_request_path(request)
    assert_equal users(:three), request.created_by
    assert_equal service_providers(:one), request.service_provider
  end

  test "rejects service request creation outside assignment scope" do
    sign_in_as users(:three)

    assert_no_difference "ServiceRequest.count" do
      post service_requests_path, params: {
        service_request: {
          customer_site_id: customer_sites(:two).id,
          service_provider_id: service_providers(:one).id,
          title: "Unauthorized alarm",
          description: "This should not be created.",
          priority: "high"
        }
      }
    end

    assert_redirected_to dashboard_path
  end

  test "triages service request to current dispatcher" do
    sign_in_as users(:one)
    request = service_requests(:one)

    patch triage_service_request_path(request)

    assert_redirected_to service_request_path(request)
    request.reload
    assert_equal "triaged", request.status
    assert_equal users(:one), request.assigned_dispatcher
  end

  test "assigns service provider and dispatcher" do
    sign_in_as users(:one)
    request = service_requests(:one)

    patch assign_service_request_path(request), params: {
      service_request: {
        service_provider_id: service_providers(:two).id
      }
    }

    assert_redirected_to service_request_path(request)
    request.reload
    assert_equal service_providers(:two), request.service_provider
    assert_equal users(:one), request.assigned_dispatcher
    assert_equal "triaged", request.status
  end

  test "rejects provider assignment without assign permission" do
    sign_in_as users(:three)
    request = service_requests(:one)

    patch assign_service_request_path(request), params: {
      service_request: {
        service_provider_id: service_providers(:two).id
      }
    }

    assert_redirected_to dashboard_path
    assert_equal service_providers(:one), request.reload.service_provider
  end

  test "records service provider response" do
    sign_in_as users(:five)
    request = service_requests(:two)

    patch respond_service_request_path(request), params: {
      service_request: {
        provider_response_summary: "Adjusted the door sensor and confirmed normal operation.",
        follow_up_notes: "Replace the sensor if the alarm returns."
      }
    }

    assert_redirected_to service_request_path(request)
    request.reload
    assert_equal "Adjusted the door sensor and confirmed normal operation.", request.provider_response_summary
    assert_equal "Replace the sensor if the alarm returns.", request.follow_up_notes
    assert_equal "triaged", request.status
  end

  test "marks provider work complete" do
    sign_in_as users(:five)
    request = service_requests(:two)

    patch respond_service_request_path(request), params: {
      service_request: {
        provider_response_summary: "Completed repair.",
        mark_provider_work_complete: "1"
      }
    }

    assert_redirected_to service_request_path(request)
    request.reload
    assert_equal "resolved", request.status
    assert request.provider_work_completed_at.present?
  end

  test "rejects provider response outside provider scope" do
    sign_in_as users(:five)
    request = service_requests(:one)

    patch respond_service_request_path(request), params: {
      service_request: {
        provider_response_summary: "Should not save."
      }
    }

    assert_redirected_to dashboard_path
    assert_nil request.reload.provider_response_summary
  end

  test "facility manager verifies resolved work" do
    sign_in_as users(:three)
    request = service_requests(:one)
    request.update!(status: "resolved", provider_work_completed_at: Time.current)

    patch verify_completion_service_request_path(request)

    assert_redirected_to service_request_path(request)
    request.reload
    assert request.completion_verified_at.present?
    assert_equal users(:three), request.completion_verified_by
  end

  test "rejects completion verification before provider work is resolved" do
    sign_in_as users(:three)
    request = service_requests(:one)

    patch verify_completion_service_request_path(request)

    assert_redirected_to service_request_path(request)
    assert_nil request.reload.completion_verified_at
  end

  test "rejects triage without triage permission" do
    sign_in_as users(:three)
    request = service_requests(:one)

    patch triage_service_request_path(request)

    assert_redirected_to dashboard_path
    assert_equal "new", request.reload.status
  end
end
