class CustomerSite < ApplicationRecord
  belongs_to :customer
  belongs_to :created_by, class_name: "User", inverse_of: :created_customer_sites

  has_many :service_requests, dependent: :restrict_with_error

  SITE_STATUSES = %w[active temporarily_closed inactive].freeze

  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :postal_code, presence: true
  validates :site_status, presence: true, inclusion: { in: SITE_STATUSES }
end
