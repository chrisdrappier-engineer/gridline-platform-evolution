require "test_helper"

class ProviderPerformanceSummaryTest < ActiveSupport::TestCase
  test "calculates provider performance from persisted metric snapshots" do
    create_metric_request(
      title: "Resolved fast response",
      status: "resolved",
      provider_response_seconds: 30.minutes.to_i,
      provider_completion_seconds: 3.hours.to_i,
      resolution_seconds: 4.hours.to_i
    )
    create_metric_request(
      title: "Resolved slow response",
      status: "resolved",
      provider_response_seconds: 90.minutes.to_i,
      provider_completion_seconds: 5.hours.to_i,
      resolution_seconds: 6.hours.to_i
    )
    create_metric_request(
      title: "Open active request",
      status: "in_progress",
      provider_response_seconds: 60.minutes.to_i
    )
    create_metric_request(title: "Canceled request", status: "canceled")

    summary = ProviderPerformanceSummary.new(ServiceRequest.where(service_provider: service_providers(:one)))

    assert_equal 5, summary.total_count
    assert_equal 2, summary.open_count
    assert_equal 2, summary.resolved_count
    assert_equal 1, summary.canceled_count
    assert_equal 50.0, summary.resolution_percentage
    assert_equal 60.minutes.to_i, summary.average_provider_response_seconds
    assert_equal 4.hours.to_i, summary.average_provider_completion_seconds
    assert_equal 5.hours.to_i, summary.average_resolution_seconds
  end

  private

  def create_metric_request(title:, status:, provider_response_seconds: nil, provider_completion_seconds: nil, resolution_seconds: nil)
    reported_at = Time.zone.parse("2026-07-10 08:00:00")
    assigned_at = reported_at + 15.minutes
    provider_responded_at = assigned_at + provider_response_seconds if provider_response_seconds
    provider_work_completed_at = assigned_at + provider_completion_seconds if provider_completion_seconds
    resolved_at = reported_at + resolution_seconds if resolution_seconds

    ServiceRequest.create!(
      customer_site: customer_sites(:one),
      service_provider: service_providers(:one),
      created_by: users(:one),
      assigned_dispatcher: users(:one),
      title: title,
      description: "Created for provider performance summary coverage.",
      priority: "normal",
      status: status,
      reported_at: reported_at,
      assigned_at: assigned_at,
      provider_responded_at: provider_responded_at,
      provider_work_completed_at: provider_work_completed_at,
      resolved_at: resolved_at
    )
  end
end
