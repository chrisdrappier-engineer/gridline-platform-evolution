class CustomerSite < ApplicationRecord
  attr_accessor :facility_manager_id

  belongs_to :customer
  belongs_to :created_by, class_name: "User", inverse_of: :created_customer_sites

  has_many :service_requests, dependent: :restrict_with_error
  has_many :facility_manager_role_assignments,
           -> { joins(:role).where(roles: { key: "facility_manager" }) },
           as: :resource,
           class_name: "UserRoleAssignment",
           dependent: :restrict_with_error
  has_many :facility_managers,
           through: :facility_manager_role_assignments,
           source: :user

  SITE_STATUSES = %w[active temporarily_closed inactive].freeze

  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :postal_code, presence: true
  validates :site_status, presence: true, inclusion: { in: SITE_STATUSES }
  validates :facility_manager_id, presence: true, if: :active_without_facility_manager?
  validate :facility_manager_id_references_active_facility_manager

  def facility_manager_assigned?
    persisted? && facility_manager_role_assignments.exists?
  end

  private

  def active_without_facility_manager?
    site_status == "active" && !facility_manager_assigned?
  end

  def facility_manager_id_references_active_facility_manager
    return if facility_manager_id.blank?
    return if facility_manager_candidate&.active? && facility_manager_candidate.role == "facility_manager"

    errors.add(:facility_manager_id, "must identify an active facility manager")
  end

  def facility_manager_candidate
    @facility_manager_candidate ||= User.find_by(id: facility_manager_id)
  end
end
