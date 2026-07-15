class ServiceRequest < ApplicationRecord
  PRIORITIES = %w[low normal high urgent].freeze
  STATUSES = %w[new triaged scheduled in_progress resolved canceled].freeze

  attr_accessor :mark_provider_work_complete

  belongs_to :customer_site
  belongs_to :service_provider
  belongs_to :created_by, class_name: "User", inverse_of: :created_service_requests
  belongs_to :assigned_dispatcher,
             class_name: "User",
             inverse_of: :assigned_service_requests,
             optional: true
  belongs_to :completion_verified_by,
             class_name: "User",
             optional: true

  has_one :service_request_quote, dependent: :restrict_with_error
  has_many :service_request_costs, dependent: :restrict_with_error

  validates :title, presence: true
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reported_at, presence: true

  def open?
    !%w[resolved canceled].include?(status)
  end

  def provider_work_complete?
    provider_work_completed_at.present?
  end

  def completion_verified?
    completion_verified_at.present?
  end

  def quote_approval_threshold_cents
    customer_site.customer.quote_approval_threshold_cents
  end

  def actual_cost_total_cents
    service_request_costs.sum(:amount_cents)
  end

  def quote_to_actual_variance_cents
    return unless service_request_quote&.approved?

    actual_cost_total_cents - service_request_quote.amount_cents
  end
end
