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
    assert_select ".metric-card", count: 3
    assert_select "a", text: service_requests(:one).title
  end

  test "dashboard only shows requests readable by scoped user" do
    sign_in_as users(:three)

    get dashboard_path

    assert_response :success
    assert_select "a", text: service_requests(:one).title
    assert_select "a", { text: service_requests(:two).title, count: 0 }
  end
end
