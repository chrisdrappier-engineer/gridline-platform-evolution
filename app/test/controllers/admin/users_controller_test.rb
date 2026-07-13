require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test "shows users to admin" do
      sign_in_as users(:six)

      get admin_users_path

      assert_response :success
      assert_select "h1", "Users"
      assert_select "turbo-frame#users_table"
      assert_select "input[name='users[search]']"
      assert_select "select[name='users[role]']"
      assert_select "select[name='users[active]']"
      assert_select "select[name='users[limit]']"
      assert_select "td", text: users(:one).email
      assert_select "td", text: roles(:dispatcher).name
    end

    test "rejects non-admin users" do
      sign_in_as users(:one)

      get admin_users_path

      assert_redirected_to dashboard_path
    end
  end
end
