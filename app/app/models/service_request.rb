class ServiceRequest < ApplicationRecord
  PRIORITIES = %w[low normal high urgent].freeze
  STATUSES = %w[new triaged scheduled in_progress resolved canceled].freeze

  belongs_to :customer_site
  belongs_to :service_provider
  belongs_to :created_by, class_name: "User", inverse_of: :created_service_requests
  belongs_to :assigned_dispatcher,
             class_name: "User",
             inverse_of: :assigned_service_requests,
             optional: true

  validates :title, presence: true
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reported_at, presence: true
end
