require "test_helper"

module Admin
  class RolePermissionsControllerTest < ActionDispatch::IntegrationTest
    test "requires sign in" do
      get admin_role_permissions_path

      assert_redirected_to login_path
    end

    test "shows permission matrix to admin" do
      sign_in_as users(:six)

      get admin_role_permissions_path

      assert_response :success
      assert_select "h1", "Permission Matrix"
      assert_select ".permission-matrix th", text: roles(:admin).name
      assert_select ".permission-matrix th", text: /Read service requests/
      assert_select ".matrix-allowed[aria-label='Admin can read service_requests']", text: "Allowed"
      assert_select ".matrix-denied[aria-label='Customer Contact cannot create service_requests']", text: "Not allowed"
    end

    test "rejects non-admin users" do
      sign_in_as users(:one)

      get admin_role_permissions_path

      assert_redirected_to dashboard_path
    end
  end
end
