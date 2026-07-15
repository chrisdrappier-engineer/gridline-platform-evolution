class ServiceRequestCost < ApplicationRecord
  CATEGORIES = %w[labor parts trip_charge emergency_fee other].freeze

  belongs_to :service_request
  belongs_to :recorded_by, class_name: "User"

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD] }
  validates :incurred_on, presence: true

  def amount_dollars
    return if amount_cents.blank?

    format("%.2f", amount_cents / 100.0)
  end

  def amount_dollars=(value)
    self.amount_cents = dollars_to_cents(value)
  end

  private

  def dollars_to_cents(value)
    return if value.blank?

    (BigDecimal(value.to_s) * 100).round
  end
end
