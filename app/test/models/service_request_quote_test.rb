require "test_helper"

class ServiceRequestQuoteTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert service_request_quotes(:one).valid?
  end

  test "requires positive amount" do
    quote = service_request_quotes(:one)
    quote.amount_cents = 0

    assert_not quote.valid?
    assert_includes quote.errors[:amount_cents], "must be greater than 0"
  end

  test "requires supported status" do
    quote = service_request_quotes(:one)
    quote.status = "waiting"

    assert_not quote.valid?
    assert_includes quote.errors[:status], "is not included in the list"
  end

  test "auto approves quote at or below customer threshold" do
    request = build_request_without_quote(customer_site: customer_sites(:one))
    quote = request.build_service_request_quote(
      created_by: users(:one),
      amount_dollars: "500.00",
      description: "Replace a failed controller."
    )

    quote.submit!(actor: users(:one))

    assert_equal "approved", quote.status
    assert_not quote.approval_required?
    assert_nil quote.approved_by
    assert quote.approved_at.present?
    assert_equal ServiceRequestQuote::AUTO_APPROVAL_NOTE, quote.approval_notes
  end

  test "requires approval above customer threshold" do
    request = build_request_without_quote(customer_site: customer_sites(:one))
    quote = request.build_service_request_quote(
      created_by: users(:one),
      amount_dollars: "500.01",
      description: "Replace compressor components."
    )

    quote.submit!(actor: users(:one))

    assert_equal "pending_approval", quote.status
    assert quote.approval_required?
    assert_nil quote.approved_at
  end

  test "amendment recalculates approval requirement and records amendment metadata" do
    quote = service_request_quotes(:one)

    quote.amend!(
      {
        amount_dollars: "900.00",
        description: "Replace controller and damaged wiring.",
        amendment_reason: "Technician found concealed wiring damage."
      },
      actor: users(:one)
    )

    assert_equal "pending_approval", quote.status
    assert quote.approval_required?
    assert_equal 40_000, quote.original_amount_cents
    assert_equal users(:one), quote.amended_by
    assert quote.amended_at.present?
  end

  private

  def build_request_without_quote(customer_site:)
    ServiceRequest.create!(
      customer_site: customer_site,
      service_provider: service_providers(:one),
      created_by: users(:one),
      title: "Quote behavior request",
      description: "Created for quote model coverage.",
      priority: "normal",
      status: "triaged",
      reported_at: Time.current
    )
  end
end
