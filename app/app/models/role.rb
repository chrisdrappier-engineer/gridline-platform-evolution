class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :user_role_assignments, dependent: :restrict_with_error
  has_many :users, through: :user_role_assignments

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
end
