require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert roles(:dispatcher).valid?
  end

  test "requires key" do
    role = roles(:dispatcher).dup
    role.key = nil

    assert_not role.valid?
    assert_includes role.errors[:key], "can't be blank"
  end

  test "requires unique key" do
    role = roles(:facility_manager).dup
    role.key = roles(:dispatcher).key

    assert_not role.valid?
    assert_includes role.errors[:key], "has already been taken"
  end
end
