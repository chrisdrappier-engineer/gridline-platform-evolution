require "test_helper"

class DemoSeedRolesTest < ActiveSupport::TestCase
  test "fixtures include at least one user assignment for each active dashboard role" do
    role_keys = User::DASHBOARD_ROLE_PRIORITY

    role_keys.each do |role_key|
      role = roles(role_key.to_sym)
      assigned_users = User.joins(user_role_assignments: :role).where(roles: { key: role.key })

      assert assigned_users.exists?, "Expected at least one assigned user for #{role.key}"
    end
  end
end
