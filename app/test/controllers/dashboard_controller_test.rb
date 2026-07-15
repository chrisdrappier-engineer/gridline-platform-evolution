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
    assert_select "a[href='#{customer_sites_path}']", text: "View Managed Sites"
    assert_select "a", text: service_requests(:one).title
  end

  test "shows customer contact dashboard" do
    sign_in_as users(:four)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Customer Contact Dashboard"
    assert_select "a[href='#{customers_path}']", text: "View Customers"
    assert_select "a[href='#{customer_sites_path}']", text: "View Sites"
  end

  test "shows service provider user dashboard" do
    sign_in_as users(:five)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Service Provider Dashboard"
    assert_select "a[href='#{service_providers_path}']", text: "View Service Providers"
    assert_select ".metric-card", text: /Avg Response Time/
    assert_select ".metric-card", text: /Resolution Rate/
    assert_select "a", text: service_requests(:two).title
  end

  test "shows admin dashboard" do
    sign_in_as users(:six)

    get dashboard_path

    assert_response :success
    assert_select "h1", "Admin Dashboard"
    assert_select ".metric-card", count: 3
    assert_select "a[href='#{admin_role_permissions_path}']", text: "Permission Matrix"
    assert_select "a[href='#{admin_role_assignments_path}']", text: "Role Assignments"
    assert_select "a[href='#{admin_users_path}']", text: "Users"
  end
end
