require "test_helper"

class ServiceRequestCostsControllerTest < ActionDispatch::IntegrationTest
  test "dispatcher records actual cost" do
    sign_in_as users(:one)
    request = service_requests(:one)

    assert_difference "ServiceRequestCost.count", 1 do
      post service_request_service_request_costs_path(request), params: {
        service_request_cost: {
          category: "labor",
          amount_dollars: "125.50",
          incurred_on: "2026-07-11",
          description: "Final labor charge."
        }
      }
    end

    assert_redirected_to service_request_path(request)
    cost = request.service_request_costs.order(:created_at).last
    assert_equal 12_550, cost.amount_cents
    assert_equal users(:one), cost.recorded_by
  end

  test "dispatcher updates actual cost" do
    sign_in_as users(:one)
    cost = service_request_costs(:one)

    patch service_request_service_request_cost_path(cost.service_request, cost), params: {
      service_request_cost: {
        category: "parts",
        amount_dollars: "99.25",
        incurred_on: "2026-07-12",
        description: "Corrected parts charge."
      }
    }

    assert_redirected_to service_request_path(cost.service_request)
    cost.reload
    assert_equal "parts", cost.category
    assert_equal 9_925, cost.amount_cents
  end

  test "facility manager cannot create actual cost" do
    sign_in_as users(:three)
    request = service_requests(:one)

    assert_no_difference "ServiceRequestCost.count" do
      post service_request_service_request_costs_path(request), params: {
        service_request_cost: {
          category: "labor",
          amount_dollars: "125.50",
          incurred_on: "2026-07-11",
          description: "Unauthorized charge."
        }
      }
    end

    assert_redirected_to dashboard_path
  end

  test "provider user cannot update actual cost" do
    sign_in_as users(:five)
    cost = service_request_costs(:two)

    patch service_request_service_request_cost_path(cost.service_request, cost), params: {
      service_request_cost: {
        category: "labor",
        amount_dollars: "1.00",
        incurred_on: "2026-07-12",
        description: "Unauthorized update."
      }
    }

    assert_redirected_to dashboard_path
    assert_not_equal 100, cost.reload.amount_cents
  end
end
