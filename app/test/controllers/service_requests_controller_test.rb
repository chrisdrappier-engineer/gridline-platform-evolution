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
    assert_select "select[name='service_request[customer_site_id]'] option[selected][value='#{customer_sites(:one).id}']"
  end

  test "shows service request detail" do
    sign_in_as users(:one)

    get service_request_path(service_requests(:one))

    assert_response :success
    assert_select "h1", service_requests(:one).title
    assert_select "form[action='#{triage_service_request_path(service_requests(:one))}']"
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

  test "triages service request to current dispatcher" do
    sign_in_as users(:one)
    request = service_requests(:one)

    patch triage_service_request_path(request)

    assert_redirected_to service_request_path(request)
    request.reload
    assert_equal "triaged", request.status
    assert_equal users(:one), request.assigned_dispatcher
  end
end
