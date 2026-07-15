require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert customers(:one).valid?
  end

  test "requires name" do
    customer = customers(:one)
    customer.name = nil

    assert_not customer.valid?
    assert_includes customer.errors[:name], "can't be blank"
  end

  test "requires supported account status" do
    customer = customers(:one)
    customer.account_status = "unknown"

    assert_not customer.valid?
    assert_includes customer.errors[:account_status], "is not included in the list"
  end

  test "requires non-negative quote approval threshold" do
    customer = customers(:one)
    customer.quote_approval_threshold_cents = -1

    assert_not customer.valid?
    assert_includes customer.errors[:quote_approval_threshold_cents], "must be greater than or equal to 0"
  end

  test "requires creator" do
    customer = customers(:one)
    customer.created_by = nil

    assert_not customer.valid?
    assert_includes customer.errors[:created_by], "must exist"
  end

  test "cannot be destroyed while it has sites" do
    customer = customers(:one)

    assert_not customer.destroy
    assert customer.persisted?
    assert customer.errors.any?
  end
end
