require "test_helper"

class ServiceProvidersControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get service_providers_path

    assert_redirected_to login_path
  end

  test "shows service provider index scoped to readable providers" do
    sign_in_as users(:five)

    get service_providers_path

    assert_response :success
    assert_select "h1", "Service Providers"
    assert_select "turbo-frame#service_providers_table"
    assert_select "input[name='service_providers[search]']"
    assert_select "select[name='service_providers[provider_type]']"
    assert_select "select[name='service_providers[status]']"
    assert_select "select[name='service_providers[limit]']"
    assert_select "a", text: service_providers(:two).name
    assert_select "a", { text: service_providers(:one).name, count: 0 }
  end

  test "shows service provider details and service requests" do
    sign_in_as users(:one)

    get service_provider_path(service_providers(:one))

    assert_response :success
    assert_select "h1", service_providers(:one).name
    assert_select "a", text: service_requests(:one).title
  end

  test "service provider user can see assigned provider only" do
    sign_in_as users(:five)

    get service_provider_path(service_providers(:two))

    assert_response :success
    assert_select "h1", service_providers(:two).name
    assert_select "a", text: service_requests(:two).title
    assert_select "a", { text: service_requests(:one).title, count: 0 }

    get service_provider_path(service_providers(:one))

    assert_redirected_to dashboard_path
  end

  test "admin creates service provider" do
    sign_in_as users(:six)

    assert_difference "ServiceProvider.count", 1 do
      post service_providers_path, params: {
        service_provider: {
          name: "Central Mechanical",
          provider_type: "vendor_partner",
          status: "active"
        }
      }
    end

    provider = ServiceProvider.order(:created_at).last
    assert_redirected_to service_provider_path(provider)
    assert_equal users(:six), provider.created_by
  end

  test "admin updates service provider" do
    sign_in_as users(:six)

    patch service_provider_path(service_providers(:two)), params: {
      service_provider: {
        name: "North Region Mechanical Partner",
        provider_type: "vendor_partner",
        status: "inactive"
      }
    }

    assert_redirected_to service_provider_path(service_providers(:two))
    assert_equal "North Region Mechanical Partner", service_providers(:two).reload.name
    assert_equal "inactive", service_providers(:two).status
  end

  test "dispatcher cannot create service provider" do
    sign_in_as users(:one)

    assert_no_difference "ServiceProvider.count" do
      post service_providers_path, params: {
        service_provider: {
          name: "Unauthorized Provider",
          provider_type: "vendor_partner",
          status: "active"
        }
      }
    end

    assert_redirected_to dashboard_path
  end
end
