require "test_helper"

class ServiceRequestCostTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert service_request_costs(:one).valid?
  end

  test "requires supported category" do
    cost = service_request_costs(:one)
    cost.category = "snacks"

    assert_not cost.valid?
    assert_includes cost.errors[:category], "is not included in the list"
  end

  test "requires positive amount" do
    cost = service_request_costs(:one)
    cost.amount_cents = 0

    assert_not cost.valid?
    assert_includes cost.errors[:amount_cents], "must be greater than 0"
  end

  test "converts dollar input to cents" do
    cost = service_request_costs(:one)

    cost.amount_dollars = "123.45"

    assert_equal 12_345, cost.amount_cents
  end
end
