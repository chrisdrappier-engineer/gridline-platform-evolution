class User < ApplicationRecord
  ROLES = %w[
    dispatcher
    operations_manager
    facility_manager
    customer_contact
    service_provider_user
    admin
  ].freeze

  has_many :user_role_assignments, dependent: :restrict_with_error
  has_many :roles, through: :user_role_assignments
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
  has_many :authored_service_request_notes,
           class_name: "ServiceRequestNote",
           foreign_key: :author_id,
           inverse_of: :author,
           dependent: :restrict_with_error
  has_many :uploaded_service_request_evidence_files,
           class_name: "ServiceRequestEvidenceFile",
           foreign_key: :uploaded_by_id,
           inverse_of: :uploaded_by,
           dependent: :restrict_with_error

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  DASHBOARD_ROLE_PRIORITY = %w[
    admin
    dispatcher
    facility_manager
    customer_contact
    service_provider_user
  ].freeze

  def dashboard_role_key
    assigned_role_keys = roles.pluck(:key)
    DASHBOARD_ROLE_PRIORITY.find { |role_key| assigned_role_keys.include?(role_key) } || role
  end
end
