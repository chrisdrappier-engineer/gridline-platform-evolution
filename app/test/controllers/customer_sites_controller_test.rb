require "test_helper"

class CustomerSitesControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get customer_sites_path

    assert_redirected_to login_path
  end

  test "shows site index scoped to readable sites" do
    sign_in_as users(:three)

    get customer_sites_path

    assert_response :success
    assert_select "h1", "Sites"
    assert_select "turbo-frame#customer_sites_table"
    assert_select "input[name='customer_sites[search]']"
    assert_select "select[name='customer_sites[site_status]']"
    assert_select "select[name='customer_sites[limit]']"
    assert_select "a", text: customer_sites(:one).name
    assert_select "a", { text: customer_sites(:two).name, count: 0 }
    assert_select "a[href='#{new_service_request_path(customer_site_id: customer_sites(:one).id)}']", text: "Create Request"
  end

  test "shows customer site details and related service requests" do
    sign_in_as users(:one)

    get customer_site_path(customer_sites(:one))

    assert_response :success
    assert_select "h1", customer_sites(:one).name
    assert_select "a[href='#{new_service_request_path(customer_site_id: customer_sites(:one).id)}']", text: "Create Service Request"
    assert_select "a", text: service_requests(:one).title
  end

  test "rejects site outside user assignment scope" do
    sign_in_as users(:three)

    get customer_site_path(customer_sites(:two))

    assert_redirected_to dashboard_path
  end
end
