require "test_helper"

class AuthorizationTest < ActiveSupport::TestCase
  test "global assignment grants permission across records" do
    user = users(:one)

    assert Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:one))
    assert Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:two))
  end

  test "site scoped assignment grants lifecycle visibility without request mutation" do
    user = users(:three)

    assert Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:one))
    assert_not Authorization.can?(user, resource: "service_requests", action: "create", target: customer_sites(:one))
    assert_not Authorization.can?(user, resource: "service_requests", action: "verify_completion", target: service_requests(:one))
  end

  test "customer scoped assignment grants permission for customer service requests" do
    user = users(:four)

    assert Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:one))
    assert_not Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:two))
  end

  test "service provider scoped assignment grants lifecycle visibility without response mutation" do
    user = users(:five)

    assert Authorization.can?(user, resource: "service_requests", action: "read", target: service_requests(:two))
    assert_not Authorization.can?(user, resource: "service_requests", action: "respond", target: service_requests(:two))
    assert_not Authorization.can?(user, resource: "service_requests", action: "respond", target: service_requests(:one))
  end

  test "authorize raises when permission is denied" do
    assert_raises Authorization::AccessDenied do
      Authorization.authorize!(
        users(:three),
        resource: "service_requests",
        action: "create",
        target: customer_sites(:two)
      )
    end
  end

  test "accessible scope returns all records for global assignment" do
    scope = Authorization.accessible_scope(
      users(:one),
      resource: "service_requests",
      action: "read",
      relation: ServiceRequest.order(:title)
    )

    assert_equal ServiceRequest.order(:title).to_a, scope.to_a
  end

  test "accessible scope filters service requests by customer site assignment" do
    scope = Authorization.accessible_scope(
      users(:three),
      resource: "service_requests",
      action: "read",
      relation: ServiceRequest.order(:title)
    )

    assert_equal [service_requests(:one)], scope.to_a
  end

  test "accessible scope filters customer sites by customer assignment" do
    scope = Authorization.accessible_scope(
      users(:four),
      resource: "customer_sites",
      action: "read",
      relation: CustomerSite.order(:name)
    )

    assert_equal [customer_sites(:one)], scope.to_a
  end

  test "accessible scope returns none without matching permission" do
    scope = Authorization.accessible_scope(
      users(:three),
      resource: "service_providers",
      action: "read",
      relation: ServiceProvider.all
    )

    assert_empty scope
  end
end
