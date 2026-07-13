require "test_helper"

module Admin
  class RoleAssignmentsControllerTest < ActionDispatch::IntegrationTest
    test "shows role assignments to admin" do
      sign_in_as users(:six)

      get admin_role_assignments_path

      assert_response :success
      assert_select "h1", "Role Assignments"
      assert_select "turbo-frame#role_assignments_table"
      assert_select "input[name='role_assignments[search]']"
      assert_select "select[name='role_assignments[role_id]']"
      assert_select "select[name='role_assignments[scope]']"
      assert_select "select[name='role_assignments[limit]']"
      assert_select "td", text: users(:one).name
      assert_select "td", text: roles(:dispatcher).name
    end

    test "rejects non-admin users" do
      sign_in_as users(:one)

      get admin_role_assignments_path

      assert_redirected_to dashboard_path
    end
  end
end
