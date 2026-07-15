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
  has_many :service_request_notes, dependent: :restrict_with_error

  before_save :populate_lifecycle_timestamps
  before_save :refresh_lifecycle_metrics

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

  def provider_responded?
    provider_responded_at.present?
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

  private

  def populate_lifecycle_timestamps
    now = Time.current

    if service_provider_id_changed_after_create?
      self.assigned_at = now
      clear_provider_lifecycle!
    elsif assigned_at.blank? && assigned_dispatcher_id.present? && will_save_change_to_assigned_dispatcher_id?
      self.assigned_at = now
    end

    self.provider_responded_at ||= now if provider_response_recorded?
    self.scheduled_at ||= now if status_changed_to?("scheduled")
    self.resolved_at ||= now if status_changed_to?("resolved")
    self.canceled_at ||= now if status_changed_to?("canceled")
  end

  def refresh_lifecycle_metrics
    self.provider_response_seconds = duration_seconds(assigned_at, provider_responded_at)
    self.provider_completion_seconds = duration_seconds(assigned_at, provider_work_completed_at)
    self.resolution_seconds = duration_seconds(reported_at, resolved_at)
    self.verification_lag_seconds = duration_seconds(provider_work_completed_at, completion_verified_at)
  end

  def duration_seconds(start_time, end_time)
    return if start_time.blank? || end_time.blank?

    [(end_time - start_time).round, 0].max
  end

  def service_provider_id_changed_after_create?
    persisted? && will_save_change_to_service_provider_id?
  end

  def provider_response_recorded?
    provider_responded_at.blank? &&
      (will_save_change_to_provider_response_summary? || will_save_change_to_follow_up_notes?)
  end

  def status_changed_to?(target_status)
    status == target_status && will_save_change_to_status?
  end

  def clear_provider_lifecycle!
    self.provider_responded_at = nil
    self.provider_work_completed_at = nil
    self.resolved_at = nil if status != "resolved"
    self.completion_verified_at = nil
    self.completion_verified_by = nil
  end
end
