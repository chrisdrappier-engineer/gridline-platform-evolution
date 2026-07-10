class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, presence: true
  validates :action, presence: true, uniqueness: { scope: :resource }
  validates :name, presence: true

  def key
    "#{resource}.#{action}"
  end
end
