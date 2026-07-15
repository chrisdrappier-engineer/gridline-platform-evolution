class ProviderPerformanceSummary
  def initialize(relation)
    @relation = relation
  end

  def total_count
    relation.count
  end

  def open_count
    relation.where.not(status: %w[resolved canceled]).count
  end

  def resolved_count
    relation.where(status: "resolved").count
  end

  def canceled_count
    relation.where(status: "canceled").count
  end

  def resolution_percentage
    denominator = relation.where.not(status: "canceled").count
    return if denominator.zero?

    ((resolved_count.to_f / denominator) * 100).round(1)
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

  attr_reader :relation

  def average_seconds(column)
    relation.where.not(column => nil).average(column)&.round
  end
end
