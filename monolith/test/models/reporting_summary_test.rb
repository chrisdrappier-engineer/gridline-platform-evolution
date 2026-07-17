require "test_helper"

class ReportingSummaryTest < ActiveSupport::TestCase
  test "calculates live metrics from the supplied relation" do
    summary = ReportingSummary.new(ServiceRequest.all)

    assert_equal 2, summary.total_count
    assert_equal 2, summary.open_count
    assert_equal 1, summary.urgent_active_count
    assert_equal 1, summary.pending_quote_approval_count
    assert_equal 86_500, summary.actual_cost_total_cents
    assert_equal 40_000, summary.approved_quote_total_cents
    assert_equal 46_500, summary.quote_to_actual_variance_cents
    assert_equal 1.0, summary.average_rating
  end

  test "keeps metrics inside the supplied scope" do
    summary = ReportingSummary.new(ServiceRequest.where(id: service_requests(:one).id))

    assert_equal 1, summary.total_count
    assert_equal 0, summary.pending_quote_approval_count
    assert_equal 22_500, summary.actual_cost_total_cents
    assert_equal 40_000, summary.approved_quote_total_cents
    assert_equal(-17_500, summary.quote_to_actual_variance_cents)
  end
end
