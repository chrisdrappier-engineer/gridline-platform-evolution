require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get dispatcher_path(users(:one))

    assert_redirected_to login_path
  end

  test "shows dispatcher profile and assigned requests" do
    sign_in_as users(:one)

    get dispatcher_path(users(:two))

    assert_response :success
    assert_select "h1", users(:two).name
    assert_select "a", text: service_requests(:two).title
  end
end
