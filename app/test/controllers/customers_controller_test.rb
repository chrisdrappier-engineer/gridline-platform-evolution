require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get customer_path(customers(:one))

    assert_redirected_to login_path
  end

  test "shows customer details, sites, and service requests" do
    sign_in_as users(:one)

    get customer_path(customers(:one))

    assert_response :success
    assert_select "h1", customers(:one).name
    assert_select "a", text: customer_sites(:one).name
    assert_select "a", text: service_requests(:one).title
  end
end
