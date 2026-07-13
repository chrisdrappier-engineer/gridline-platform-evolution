require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert role_permissions(:dispatcher_service_requests_read).valid?
  end

  test "requires unique permission per role" do
    role_permission = role_permissions(:dispatcher_service_requests_create).dup
    role_permission.permission = permissions(:service_requests_read)

    assert_not role_permission.valid?
    assert_includes role_permission.errors[:permission_id], "has already been taken"
  end
end
