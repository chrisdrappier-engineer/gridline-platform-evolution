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
end
