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

  test "refreshes lifecycle metric snapshots from timestamps" do
    request = service_requests(:one)
    reported_at = Time.zone.parse("2026-07-10 08:00:00")
    assigned_at = reported_at + 30.minutes
    provider_responded_at = assigned_at + 20.minutes
    provider_work_completed_at = assigned_at + 3.hours
    resolved_at = provider_work_completed_at + 15.minutes
    completion_verified_at = provider_work_completed_at + 45.minutes

    request.update!(
      reported_at: reported_at,
      assigned_at: assigned_at,
      provider_responded_at: provider_responded_at,
      provider_work_completed_at: provider_work_completed_at,
      status: "resolved",
      resolved_at: resolved_at,
      completion_verified_at: completion_verified_at,
      completion_verified_by: users(:one)
    )

    assert_equal 20.minutes.to_i, request.provider_response_seconds
    assert_equal 3.hours.to_i, request.provider_completion_seconds
    assert_equal 3.hours.to_i + 45.minutes.to_i, request.resolution_seconds
    assert_equal 45.minutes.to_i, request.verification_lag_seconds
  end

  test "populates lifecycle timestamps from status and response changes" do
    request = service_requests(:one)

    request.update!(
      assigned_dispatcher: users(:one),
      provider_response_summary: "Provider acknowledged the request.",
      status: "scheduled"
    )

    assert request.assigned_at.present?
    assert request.provider_responded_at.present?
    assert request.scheduled_at.present?
    assert request.provider_response_seconds.present?
  end
end
