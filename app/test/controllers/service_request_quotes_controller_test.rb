require "test_helper"

class ServiceRequestQuotesControllerTest < ActionDispatch::IntegrationTest
  test "dispatcher submits auto-approved quote under threshold" do
    sign_in_as users(:one)
    request = create_request_without_quote(customer_site: customer_sites(:one))

    assert_difference "ServiceRequestQuote.count", 1 do
      post service_request_service_request_quote_path(request), params: {
        service_request_quote: {
          amount_dollars: "450.00",
          description: "Replace thermostat controller."
        }
      }
    end

    assert_redirected_to service_request_path(request)
    quote = request.reload.service_request_quote
    assert_equal "approved", quote.status
    assert_not quote.approval_required?
  end

  test "dispatcher submits quote requiring approval above threshold" do
    sign_in_as users(:one)
    request = create_request_without_quote(customer_site: customer_sites(:one))

    post service_request_service_request_quote_path(request), params: {
      service_request_quote: {
        amount_dollars: "950.00",
        description: "Replace compressor components."
      }
    }

    quote = request.reload.service_request_quote
    assert_equal "pending_approval", quote.status
    assert quote.approval_required?
  end

  test "dispatcher amends quote and recalculates approval" do
    sign_in_as users(:one)
    quote = service_request_quotes(:one)

    patch service_request_service_request_quote_path(quote.service_request), params: {
      service_request_quote: {
        amount_dollars: "900.00",
        description: "Replace controller and damaged wiring.",
        amendment_reason: "Technician found concealed wiring damage."
      }
    }

    assert_redirected_to service_request_path(quote.service_request)
    quote.reload
    assert_equal "pending_approval", quote.status
    assert_equal 40_000, quote.original_amount_cents
    assert_equal users(:one), quote.amended_by
  end

  test "facility manager approves pending quote for assigned site" do
    sign_in_as users(:three)
    request = create_request_without_quote(customer_site: customer_sites(:one))
    quote = create_pending_quote(request)

    patch approve_service_request_service_request_quote_path(request)

    assert_redirected_to service_request_path(request)
    quote.reload
    assert_equal "approved", quote.status
    assert_equal users(:three), quote.approved_by
  end

  test "facility manager rejects pending quote for assigned site" do
    sign_in_as users(:three)
    request = create_request_without_quote(customer_site: customer_sites(:one))
    quote = create_pending_quote(request)

    patch reject_service_request_service_request_quote_path(request), params: {
      service_request_quote: {
        approval_notes: "Please call before proceeding."
      }
    }

    assert_redirected_to service_request_path(request)
    quote.reload
    assert_equal "rejected", quote.status
    assert_equal users(:three), quote.rejected_by
    assert_equal "Please call before proceeding.", quote.approval_notes
  end

  test "facility manager cannot approve quote outside assigned site" do
    sign_in_as users(:three)
    quote = service_request_quotes(:two)

    patch approve_service_request_service_request_quote_path(quote.service_request)

    assert_redirected_to dashboard_path
    assert_equal "pending_approval", quote.reload.status
  end

  test "provider user cannot create quote" do
    sign_in_as users(:five)
    request = create_request_without_quote(customer_site: customer_sites(:two), service_provider: service_providers(:two))

    assert_no_difference "ServiceRequestQuote.count" do
      post service_request_service_request_quote_path(request), params: {
        service_request_quote: {
          amount_dollars: "800.00",
          description: "Unauthorized quote."
        }
      }
    end

    assert_redirected_to dashboard_path
  end

  private

  def create_request_without_quote(customer_site:, service_provider: service_providers(:one))
    ServiceRequest.create!(
      customer_site: customer_site,
      service_provider: service_provider,
      created_by: users(:one),
      title: "Quote controller request",
      description: "Created for quote controller coverage.",
      priority: "normal",
      status: "triaged",
      reported_at: Time.current
    )
  end

  def create_pending_quote(request)
    request.create_service_request_quote!(
      created_by: users(:one),
      amount_cents: request.quote_approval_threshold_cents + 10_000,
      currency: "USD",
      description: "Approval-required quote.",
      status: "pending_approval",
      approval_required: true,
      submitted_at: Time.current
    )
  end
end
