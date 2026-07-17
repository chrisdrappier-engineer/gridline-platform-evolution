class DashboardReportingSection
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  def initialize(summary, loaded_at: Time.current)
    @summary = summary
    @loaded_at = loaded_at
  end

  def freshness_label
    "Calculated live from authorized operational records at #{loaded_at.strftime('%-I:%M %p')}."
  end

  def operations_cards
    [
      card("Visible Requests", summary.total_count),
      card("Open Requests", summary.open_count),
      card("Urgent Active", summary.urgent_active_count, "metric-card urgent"),
      card("Pending Quote Approval", summary.pending_quote_approval_count),
      card("Follow-Ups Needed", summary.follow_up_needed_count),
      card("Follow-Up Requests", summary.follow_up_request_count)
    ]
  end

  def financial_cards
    [
      card("Approved Quotes", money(summary.approved_quote_total_cents)),
      card("Actual Costs", money(summary.actual_cost_total_cents)),
      card("Quote Variance", money(summary.quote_to_actual_variance_cents))
    ]
  end

  def quality_cards
    [
      card("Average Rating", rating(summary.average_rating)),
      card("Resolved Requests", summary.resolved_count),
      card("Completed Without Feedback", summary.completed_without_feedback_count)
    ]
  end

  def performance_cards
    [
      card("Avg Provider Response", duration(summary.average_provider_response_seconds)),
      card("Avg Provider Completion", duration(summary.average_provider_completion_seconds)),
      card("Avg Resolution", duration(summary.average_resolution_seconds))
    ]
  end

  private

  attr_reader :summary, :loaded_at

  def card(label, value, css_class = "metric-card")
    ReportingMetricCard.new(label:, value:, css_class:)
  end

  def money(amount_cents)
    number_to_currency(amount_cents / 100.0)
  end

  def rating(value)
    value ? "#{value} / 5" : "Not enough data"
  end

  def duration(seconds)
    return "Not enough data" if seconds.nil?

    distance_of_time_in_words(seconds.seconds)
  end
end
