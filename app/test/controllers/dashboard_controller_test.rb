require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get dashboard_path

    assert_redirected_to login_path
  end

  test "shows dispatcher dashboard for signed in user" do
    sign_in_as users(:one)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Dispatcher Dashboard"
    assert_select "a", text: service_requests(:one).title
  end

  test "dashboard only shows requests readable by scoped user" do
    sign_in_as users(:three)

    get dashboard_path

    assert_response :success
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }
  end

  test "shows facility manager dashboard" do
    sign_in_as users(:three)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Facility Manager Dashboard"
    assert_select "a", text: /#{customer_sites(:one).name}/
    assert_select "a", { text: /#{customer_sites(:two).name}/, count: 0 }
  end

  test "shows customer contact dashboard" do
    sign_in_as users(:four)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Customer Contact Dashboard"
    assert_select "a", text: customers(:one).name
    assert_select "a", { text: customers(:two).name, count: 0 }
  end

  test "shows service provider user dashboard" do
    sign_in_as users(:five)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Service Provider Dashboard"
    assert_select "a", text: service_providers(:two).name
    assert_select "a", { text: service_providers(:one).name, count: 0 }
  end

  test "shows admin dashboard" do
    sign_in_as users(:six)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Admin Dashboard"
    assert_select ".metric-card", count: 3
    assert_select "h2", "Role Permission Matrix"
    assert_select ".permission-matrix th", text: roles(:admin).name
    assert_select ".permission-matrix th", text: /Read service requests/
    assert_select ".matrix-allowed[aria-label='Admin can read service_requests']", text: "Allowed"
    assert_select ".matrix-denied[aria-label='Customer Contact cannot create service_requests']", text: "Not allowed"
    assert_select "li", text: roles(:admin).name
  end
end
