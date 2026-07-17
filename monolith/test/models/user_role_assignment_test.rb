require "test_helper"

class UserRoleAssignmentTest < ActiveSupport::TestCase
  test "valid global fixture" do
    assert user_role_assignments(:dispatcher_global).valid?
    assert user_role_assignments(:dispatcher_global).global?
  end

  test "valid scoped fixture" do
    assignment = user_role_assignments(:facility_manager_site)

    assert assignment.valid?
    assert_not assignment.global?
  end

  test "requires complete resource scope" do
    assignment = user_role_assignments(:facility_manager_site).dup
    assignment.resource_id = nil

    assert_not assignment.valid?
    assert_includes assignment.errors[:resource], "scope must be fully present or fully blank"
  end

  test "requires unique role assignment per scope" do
    assignment = user_role_assignments(:facility_manager_site).dup

    assert_not assignment.valid?
    assert_includes assignment.errors[:role_id], "has already been taken"
  end
end
