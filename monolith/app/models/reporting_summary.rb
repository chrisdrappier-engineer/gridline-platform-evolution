class ReportingSummary
  OPEN_STATUSES = %w[new triaged scheduled in_progress].freeze

  def initialize(relation)
    @request_relation = relation.except(:includes, :preload, :eager_load, :order).distinct
  end

  def total_count
    request_relation.count
  end

  def open_count
    request_relation.where(status: OPEN_STATUSES).count
  end

  def resolved_count
    request_relation.where(status: "resolved").count
  end

  def urgent_active_count
    request_relation.where(priority: "urgent", status: OPEN_STATUSES).count
  end

  def pending_quote_approval_count
    quotes.where(status: "pending_approval", approval_required: true).count
  end

  def follow_up_needed_count
    feedbacks.where(follow_up_needed: true).count
  end

  def follow_up_request_count
    request_relation.where.not(follow_up_to_service_request_id: nil).count
  end

  def completed_without_feedback_count
    request_relation
      .where(status: "resolved")
      .left_outer_joins(:service_request_feedback)
      .where(service_request_feedbacks: { id: nil })
      .count
  end

  def approved_quote_total_cents
    quotes.where(status: "approved").sum(:amount_cents)
  end

  def actual_cost_total_cents
    costs.sum(:amount_cents)
  end

  def quote_to_actual_variance_cents
    actual_cost_total_cents - approved_quote_total_cents
  end

  def average_rating
    feedbacks.average(:rating)&.round(1)
  end

  def average_provider_response_seconds
    average_seconds(:provider_response_seconds)
  end

  def average_provider_completion_seconds
    average_seconds(:provider_completion_seconds)
  end

  def average_resolution_seconds
    average_seconds(:resolution_seconds)
  end

  private

  attr_reader :request_relation

  def request_ids
    request_relation.select(:id)
  end

  def quotes
    ServiceRequestQuote.where(service_request_id: request_ids)
  end

  def costs
    ServiceRequestCost.where(service_request_id: request_ids)
  end

  def feedbacks
    ServiceRequestFeedback.where(service_request_id: request_ids)
  end

  def average_seconds(column)
    request_relation.where.not(column => nil).average(column)&.round
  end
end
