require "test_helper"

class CustomerSitesControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get customer_site_path(customer_sites(:one))

    assert_redirected_to login_path
  end

  test "shows customer site details and related service requests" do
    sign_in_as users(:one)

    get customer_site_path(customer_sites(:one))

    assert_response :success
    assert_select "h1", customer_sites(:one).name
    assert_select "a", text: service_requests(:one).title
  end
end
