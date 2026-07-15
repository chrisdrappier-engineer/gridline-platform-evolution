require "test_helper"

class ServiceRequestTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert service_requests(:one).valid?
  end

  test "allows unassigned dispatcher before triage" do
    request = service_requests(:one)
    request.assigned_dispatcher = nil

    assert request.valid?
  end

  test "requires site provider and creator" do
    request = service_requests(:one)
    request.customer_site = nil
    request.service_provider = nil
    request.created_by = nil

    assert_not request.valid?
    assert_includes request.errors[:customer_site], "must exist"
    assert_includes request.errors[:service_provider], "must exist"
    assert_includes request.errors[:created_by], "must exist"
  end

  test "requires title and reported time" do
    request = service_requests(:one)
    request.title = nil
    request.reported_at = nil

    assert_not request.valid?
    assert_includes request.errors[:title], "can't be blank"
    assert_includes request.errors[:reported_at], "can't be blank"
  end

  test "requires supported priority" do
    request = service_requests(:one)
    request.priority = "immediate"

    assert_not request.valid?
    assert_includes request.errors[:priority], "is not included in the list"
  end

  test "requires supported status" do
    request = service_requests(:one)
    request.status = "waiting"

    assert_not request.valid?
    assert_includes request.errors[:status], "is not included in the list"
  end

  test "calculates actual cost total and quote variance" do
    request = service_requests(:one)

    assert_equal 22_500, request.actual_cost_total_cents
    assert_equal(-17_500, request.quote_to_actual_variance_cents)
  end
end
