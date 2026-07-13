require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "shows sign in form" do
    get login_path

    assert_response :success
    assert_select "h1", "Sign in to Gridline Operations"
  end

  test "signs in active user with stub password" do
    post login_path, params: {
      session: {
        email: users(:one).email,
        password: "gridline"
      }
    }

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".flash-notice", /Signed in as Dana Dispatcher/
  end

  test "rejects invalid stub password" do
    post login_path, params: {
      session: {
        email: users(:one).email,
        password: "wrong"
      }
    }

    assert_redirected_to login_path
  end
end
