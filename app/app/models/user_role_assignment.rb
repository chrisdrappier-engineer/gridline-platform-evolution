class UserRoleAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :resource, polymorphic: true, optional: true

  validates :role_id, uniqueness: { scope: [:user_id, :resource_type, :resource_id] }
  validate :resource_scope_is_complete

  def global?
    resource_type.blank? && resource_id.blank?
  end

  private

  def resource_scope_is_complete
    return if resource_type.present? == resource_id.present?

    errors.add(:resource, "scope must be fully present or fully blank")
  end
end
