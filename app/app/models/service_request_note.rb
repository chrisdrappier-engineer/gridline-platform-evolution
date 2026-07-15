class ServiceRequestNote < ApplicationRecord
  NOTE_TYPES = %w[general intake provider_update customer_update resolution].freeze
  VISIBILITIES = %w[internal customer_visible provider_visible shared].freeze
  INTERNAL_ROLE_KEYS = %w[admin dispatcher].freeze
  CUSTOMER_ROLE_KEYS = %w[facility_manager customer_contact].freeze
  PROVIDER_ROLE_KEYS = %w[service_provider_user].freeze

  belongs_to :service_request
  belongs_to :author, class_name: "User"

  validates :note_type, presence: true, inclusion: { in: NOTE_TYPES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :body, presence: true
  validate :visibility_allowed_for_author

  scope :chronological, -> { order(created_at: :asc, id: :asc) }
  scope :visible_to, ->(user) { where(visibility: visible_visibilities_for(user)) }

  def self.visible_visibilities_for(user)
    role_keys = user_role_keys(user)
    visibilities = []
    visibilities.concat(VISIBILITIES) if (role_keys & INTERNAL_ROLE_KEYS).any?
    visibilities.concat(%w[customer_visible shared]) if (role_keys & CUSTOMER_ROLE_KEYS).any?
    visibilities.concat(%w[provider_visible shared]) if (role_keys & PROVIDER_ROLE_KEYS).any?
    visibilities.uniq
  end

  def self.allowed_visibilities_for(user)
    role_keys = user_role_keys(user)
    return VISIBILITIES if (role_keys & INTERNAL_ROLE_KEYS).any?
    return %w[customer_visible shared] if (role_keys & CUSTOMER_ROLE_KEYS).any?
    return %w[provider_visible shared] if (role_keys & PROVIDER_ROLE_KEYS).any?

    []
  end

  def self.default_visibility_for(user)
    allowed_visibilities_for(user).first || "shared"
  end

  def self.visibility_options_for(user)
    allowed_visibilities_for(user).map { |visibility| [visibility.humanize, visibility] }
  end

  def self.note_type_options
    NOTE_TYPES.map { |note_type| [note_type.humanize, note_type] }
  end

  def visibility_label
    visibility.humanize
  end

  def note_type_label
    note_type.humanize
  end

  private

  def self.user_role_keys(user)
    return [] unless user

    user.roles.pluck(:key).presence || [user.role]
  end

  def visibility_allowed_for_author
    return if author.blank? || visibility.blank?
    return if self.class.allowed_visibilities_for(author).include?(visibility)

    errors.add(:visibility, "is not available for this user")
  end
end
