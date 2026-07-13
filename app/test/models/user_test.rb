require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert users(:one).valid?
  end

  test "requires email" do
    user = users(:one).dup
    user.email = nil

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    user = users(:two).dup
    user.email = users(:one).email

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires supported role" do
    user = users(:one).dup
    user.email = "other@example.com"
    user.role = "customer"

    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "cannot be destroyed while it owns records" do
    user = users(:one)

    assert_not user.destroy
    assert user.persisted?
    assert user.errors.any?
  end
end
