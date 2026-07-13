require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get customers_path

    assert_redirected_to login_path
  end

  test "shows customer index scoped to readable customers" do
    sign_in_as users(:four)

    get customers_path

    assert_response :success
    assert_select "h1", "Customers"
    assert_select "turbo-frame#customers_table"
    assert_select "input[name='customers[search]']"
    assert_select "select[name='customers[account_status]']"
    assert_select "select[name='customers[limit]']"
    assert_select "a", text: customers(:one).name
    assert_select "a", { text: customers(:two).name, count: 0 }
  end

  test "shows customer details, sites, and service requests" do
    sign_in_as users(:one)

    get customer_path(customers(:one))

    assert_response :success
    assert_select "h1", customers(:one).name
    assert_select "a", text: customer_sites(:one).name
    assert_select "a", text: service_requests(:one).title
    assert_select "a[href='#{new_service_request_path(customer_id: customers(:one).id)}']", text: "Create Service Request"
  end

  test "customer contact can see assigned customer only" do
    sign_in_as users(:four)

    get customer_path(customers(:one))

    assert_response :success
    assert_select "h1", customers(:one).name
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }

    get customer_path(customers(:two))

    assert_redirected_to dashboard_path
  end

  test "admin creates customer" do
    sign_in_as users(:six)

    assert_difference "Customer.count", 1 do
      post customers_path, params: {
        customer: {
          name: "Lakeview Facilities",
          account_status: "onboarding",
          industry: "property_management"
        }
      }
    end

    customer = Customer.order(:created_at).last
    assert_redirected_to customer_path(customer)
    assert_equal users(:six), customer.created_by
  end

  test "admin updates customer" do
    sign_in_as users(:six)

    patch customer_path(customers(:one)), params: {
      customer: {
        name: "Northstar Facilities Group",
        account_status: "suspended",
        industry: "property_management"
      }
    }

    assert_redirected_to customer_path(customers(:one))
    assert_equal "Northstar Facilities Group", customers(:one).reload.name
    assert_equal "suspended", customers(:one).account_status
  end

  test "dispatcher cannot create customer" do
    sign_in_as users(:one)

    assert_no_difference "Customer.count" do
      post customers_path, params: {
        customer: {
          name: "Unauthorized Customer",
          account_status: "active",
          industry: "warehousing"
        }
      }
    end

    assert_redirected_to dashboard_path
  end
end
