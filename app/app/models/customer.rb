class Customer < ApplicationRecord
  ACCOUNT_STATUSES = %w[active onboarding suspended inactive].freeze

  belongs_to :created_by, class_name: "User", inverse_of: :created_customers

  has_many :customer_sites, dependent: :restrict_with_error

  validates :name, presence: true
  validates :account_status, presence: true, inclusion: { in: ACCOUNT_STATUSES }
  validates :quote_approval_threshold_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
