require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert permissions(:service_requests_read).valid?
  end

  test "requires resource and action" do
    permission = permissions(:service_requests_read).dup
    permission.resource = nil
    permission.action = nil

    assert_not permission.valid?
    assert_includes permission.errors[:resource], "can't be blank"
    assert_includes permission.errors[:action], "can't be blank"
  end

  test "requires unique action within resource" do
    permission = permissions(:service_requests_create).dup
    permission.action = permissions(:service_requests_read).action

    assert_not permission.valid?
    assert_includes permission.errors[:action], "has already been taken"
  end

  test "derives display key" do
    assert_equal "service_requests.read", permissions(:service_requests_read).key
  end
end
