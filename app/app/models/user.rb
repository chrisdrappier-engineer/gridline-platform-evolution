class User < ApplicationRecord
  ROLES = %w[dispatcher operations_manager admin].freeze

  has_many :created_customers,
           class_name: "Customer",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_error
  has_many :created_customer_sites,
           class_name: "CustomerSite",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_error
  has_many :created_service_providers,
           class_name: "ServiceProvider",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_error
  has_many :created_service_requests,
           class_name: "ServiceRequest",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_error
  has_many :assigned_service_requests,
           class_name: "ServiceRequest",
           foreign_key: :assigned_dispatcher_id,
           inverse_of: :assigned_dispatcher,
           dependent: :restrict_with_error

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
end
