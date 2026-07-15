class ServiceRequestQuote < ApplicationRecord
  STATUSES = %w[draft pending_approval approved rejected canceled].freeze
  AUTO_APPROVAL_NOTE = "Auto-approved under customer quote approval threshold.".freeze

  belongs_to :service_request
  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  belongs_to :amended_by, class_name: "User", optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD] }
  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :service_request_id, uniqueness: true
  validates :amendment_reason, presence: true, if: -> { amended_at.present? }

  def amount_dollars
    return if amount_cents.blank?

    format("%.2f", amount_cents / 100.0)
  end

  def amount_dollars=(value)
    self.amount_cents = dollars_to_cents(value)
  end

  def approved?
    status == "approved"
  end

  def pending_approval?
    status == "pending_approval"
  end

  def rejected?
    status == "rejected"
  end

  def submit!(actor:)
    self.submitted_at ||= Time.current
    clear_decision!
    apply_approval_policy!
    save!
  end

  def amend!(attributes, actor:)
    self.original_amount_cents ||= amount_cents
    assign_attributes(attributes)
    self.amended_by = actor
    self.amended_at = Time.current
    submit!(actor: actor)
  end

  def approve!(actor:, notes: nil)
    update!(
      status: "approved",
      approval_required: true,
      approved_by: actor,
      approved_at: Time.current,
      rejected_by: nil,
      rejected_at: nil,
      approval_notes: notes.presence || approval_notes
    )
  end

  def reject!(actor:, notes: nil)
    update!(
      status: "rejected",
      rejected_by: actor,
      rejected_at: Time.current,
      approved_by: nil,
      approved_at: nil,
      approval_notes: notes.presence || approval_notes
    )
  end

  private

  def dollars_to_cents(value)
    return if value.blank?

    (BigDecimal(value.to_s) * 100).round
  end

  def apply_approval_policy!
    self.approval_required = amount_cents > service_request.quote_approval_threshold_cents

    if approval_required
      self.status = "pending_approval"
    else
      self.status = "approved"
      self.approved_by = nil
      self.approved_at = Time.current
      self.approval_notes = AUTO_APPROVAL_NOTE
    end
  end

  def clear_decision!
    self.approved_by = nil
    self.approved_at = nil
    self.rejected_by = nil
    self.rejected_at = nil
  end
end
