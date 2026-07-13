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
    assert_select "turbo-frame#service_requests_table"
    assert_select "input[name='service_requests[search]']"
    assert_select "select[name='service_requests[limit]'] option[value='10']"
    assert_select "select[name='service_requests[limit]'] option[value='20'][selected]"
    assert_select "select[name='service_requests[limit]'] option[value='30']"
    assert_select "a[href*='service_requests%5Bsort%5D=request']", text: /Request/
    assert_select "a[href*='service_requests%5Bsort%5D=dispatcher']", text: /Dispatcher/
    assert_select "select[name='service_requests[dispatcher_id]'] option[value='unassigned']", text: "Unassigned"
    assert_select "a", text: service_requests(:one).title
    assert_select "a[href='#{service_provider_path(service_providers(:one))}']", text: service_providers(:one).name
    assert_select "a[href='#{customer_path(customers(:one))}']", text: customers(:one).name
    assert_select "a[href='#{customer_site_path(customer_sites(:one))}']", text: customer_sites(:one).name
    assert_select "a[href='#{dispatcher_path(users(:two))}']", text: users(:two).name
    assert_select ".status-new", text: "New"
  end

  test "service request queue paginates when result count exceeds page size" do
    sign_in_as users(:one)
    create_table_requests(count: 30)

    get service_requests_path

    assert_response :success
    assert_select ".pagination"
    assert_select ".table-results", text: /1-20 of 32/
  end

  test "service request queue supports whitelisted page size choices" do
    sign_in_as users(:one)
    create_table_requests(count: 30)

    get service_requests_path(service_requests: { limit: "10" })

    assert_response :success
    assert_select ".table-results", text: /1-10 of 32/
    assert_select "select[name='service_requests[limit]'] option[value='10'][selected]"

    get service_requests_path(service_requests: { limit: "99" })

    assert_response :success
    assert_select ".table-results", text: /1-20 of 32/
    assert_select "select[name='service_requests[limit]'] option[value='20'][selected]"
  end

  test "service request queue searches on the backend" do
    sign_in_as users(:one)
    create_table_requests(count: 1, title_prefix: "Generator coolant variance")
    create_table_requests(count: 1, title_prefix: "Parking gate inspection")

    get service_requests_path(service_requests: { search: "coolant" })

    assert_response :success
    assert_select "a", text: /Generator coolant variance/
    assert_select "a", { text: /Parking gate inspection/, count: 0 }
    assert_select ".table-results", text: /1-1 of 1/
  end

  test "service request queue applies whitelisted server sort" do
    sign_in_as users(:one)
    older = create_table_requests(count: 1, title_prefix: "AAA older request", reported_at: 3.days.ago).first
    newer = create_table_requests(count: 1, title_prefix: "ZZZ newer request", reported_at: 2.days.ago).first

    get service_requests_path(service_requests: { sort: "request", direction: "asc" })

    assert_response :success
    assert_select "tbody tr:first-child a", text: older.title

    get service_requests_path(service_requests: { sort: "not_allowed", direction: "sideways" })

    assert_response :success
    assert_select "tbody tr:first-child a", text: newer.title
  end

  test "service request queue sorts by dispatcher" do
    sign_in_as users(:one)
    dana_request = create_table_requests(
      count: 1,
      title_prefix: "Dana assigned request",
      assigned_dispatcher: users(:one),
      status: "scheduled"
    ).first
    morgan_request = create_table_requests(
      count: 1,
      title_prefix: "Morgan assigned request",
      assigned_dispatcher: users(:two),
      status: "scheduled"
    ).first

    get service_requests_path(service_requests: { status: "scheduled", sort: "dispatcher", direction: "asc" })

    assert_response :success
    assert_select "tbody tr:first-child a", text: dana_request.title

    get service_requests_path(service_requests: { status: "scheduled", sort: "dispatcher", direction: "desc" })

    assert_response :success
    assert_select "tbody tr:first-child a", text: morgan_request.title
  end

  test "service request queue filters by dispatcher and unassigned requests" do
    sign_in_as users(:one)

    get service_requests_path(service_requests: { dispatcher_id: users(:two).id })

    assert_response :success
    assert_select "a", text: service_requests(:two).title
    assert_select "a", { text: service_requests(:one).title, count: 0 }

    get service_requests_path(service_requests: { dispatcher_id: "unassigned" })

    assert_response :success
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }
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
    assert_select "a[href='#{edit_service_request_path(service_requests(:one))}']", text: "Edit Request"
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

  test "dispatcher updates service request details" do
    sign_in_as users(:one)

    patch service_request_path(service_requests(:one)), params: {
      service_request: {
        title: "Updated lobby HVAC issue",
        description: "Tenant reports cycling equipment after reset.",
        priority: "urgent",
        status: "in_progress"
      }
    }

    assert_redirected_to service_request_path(service_requests(:one))
    service_requests(:one).reload
    assert_equal "Updated lobby HVAC issue", service_requests(:one).title
    assert_equal "urgent", service_requests(:one).priority
    assert_equal "in_progress", service_requests(:one).status
  end

  test "facility manager cannot update service request details" do
    sign_in_as users(:three)

    patch service_request_path(service_requests(:one)), params: {
      service_request: {
        title: "Unauthorized title",
        priority: "urgent",
        status: "in_progress"
      }
    }

    assert_redirected_to dashboard_path
    assert_not_equal "Unauthorized title", service_requests(:one).reload.title
  end

  test "facility manager cannot create request directly" do
    sign_in_as users(:three)

    assert_no_difference "ServiceRequest.count" do
      post service_requests_path, params: {
        service_request: {
          customer_site_id: customer_sites(:one).id,
          title: "Tenant entry light outage",
          description: "Entry light is out near the main lobby.",
          priority: "normal"
        }
      }
    end

    assert_redirected_to dashboard_path
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

  test "dispatcher records provider response" do
    sign_in_as users(:one)
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

  test "dispatcher marks provider work complete" do
    sign_in_as users(:one)
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

  test "rejects provider user response because providers track lifecycle only" do
    sign_in_as users(:five)
    request = service_requests(:two)

    patch respond_service_request_path(request), params: {
      service_request: {
        provider_response_summary: "Should not save."
      }
    }

    assert_redirected_to dashboard_path
    assert_nil request.reload.provider_response_summary
  end

  test "dispatcher verifies resolved work" do
    sign_in_as users(:one)
    request = service_requests(:one)
    request.update!(status: "resolved", provider_work_completed_at: Time.current)

    patch verify_completion_service_request_path(request)

    assert_redirected_to service_request_path(request)
    request.reload
    assert request.completion_verified_at.present?
    assert_equal users(:one), request.completion_verified_by
  end

  test "rejects completion verification before provider work is resolved" do
    sign_in_as users(:one)
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

  private

  def create_table_requests(
    count:,
    title_prefix: "Table request",
    reported_at: Time.zone.parse("2026-07-12 08:00:00"),
    assigned_dispatcher: nil,
    status: nil
  )
    count.times.map do |index|
      ServiceRequest.create!(
        customer_site: customer_sites(:one),
        service_provider: service_providers(:one),
        created_by: users(:one),
        assigned_dispatcher: assigned_dispatcher || (index.even? ? users(:one) : nil),
        title: "#{title_prefix} #{index + 1}",
        description: "Created for table behavior coverage.",
        priority: ServiceRequest::PRIORITIES[index % ServiceRequest::PRIORITIES.length],
        status: status || ServiceRequest::STATUSES[index % ServiceRequest::STATUSES.length],
        reported_at: reported_at + index.minutes
      )
    end
  end
end
