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
end
