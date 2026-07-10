class ServiceProvider < ApplicationRecord
  PROVIDER_TYPES = %w[internal_team vendor_partner].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :created_by, class_name: "User", inverse_of: :created_service_providers

  has_many :service_requests, dependent: :restrict_with_error

  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
