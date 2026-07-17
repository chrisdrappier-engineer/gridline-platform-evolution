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
    assert_select "a[href='#{new_service_request_path(customer_site_id: customer_sites(:one).id)}']", { text: "Create Request", count: 0 }
  end

  test "shows customer site details and related service requests" do
    sign_in_as users(:one)

    get customer_site_path(customer_sites(:one))

    assert_response :success
    assert_select "h1", customer_sites(:one).name
    assert_select "a[href='#{new_service_request_path(customer_site_id: customer_sites(:one).id)}']", text: "Create Service Request"
    assert_select "a", text: service_requests(:one).title
    assert_select "dd", text: users(:three).name
  end

  test "rejects site outside user assignment scope" do
    sign_in_as users(:three)

    get customer_site_path(customer_sites(:two))

    assert_redirected_to dashboard_path
  end

  test "admin creates customer site" do
    sign_in_as users(:six)

    assert_difference "CustomerSite.count", 1 do
      post customer_sites_path, params: {
        customer_site: {
          customer_id: customers(:one).id,
          name: "Northstar Uptown",
          address_line_1: "200 North Ave",
          city: "Chicago",
          state: "IL",
          postal_code: "60610",
          site_status: "active",
          facility_manager_id: users(:three).id
        }
      }
    end

    site = CustomerSite.order(:created_at).last
    assert_redirected_to customer_site_path(site)
    assert_equal users(:six), site.created_by
    assert_includes site.facility_managers, users(:three)
  end

  test "admin cannot create active customer site without facility manager" do
    sign_in_as users(:six)

    assert_no_difference "CustomerSite.count" do
      post customer_sites_path, params: {
        customer_site: {
          customer_id: customers(:one).id,
          name: "Northstar Unmanaged",
          address_line_1: "300 North Ave",
          city: "Chicago",
          state: "IL",
          postal_code: "60611",
          site_status: "active"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /Facility manager can't be blank/
  end

  test "admin updates customer site" do
    sign_in_as users(:six)

    patch customer_site_path(customer_sites(:one)), params: {
      customer_site: {
        name: "Northstar Loop",
        site_status: "temporarily_closed"
      }
    }

    assert_redirected_to customer_site_path(customer_sites(:one))
    assert_equal "Northstar Loop", customer_sites(:one).reload.name
    assert_equal "temporarily_closed", customer_sites(:one).site_status
  end

  test "non-admin cannot create customer site" do
    sign_in_as users(:one)

    assert_no_difference "CustomerSite.count" do
      post customer_sites_path, params: {
        customer_site: {
          customer_id: customers(:one).id,
          name: "Unauthorized Site",
          address_line_1: "1 Test Way",
          city: "Chicago",
          state: "IL",
          postal_code: "60601",
          site_status: "active"
        }
      }
    end

    assert_redirected_to dashboard_path
  end
end
