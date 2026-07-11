require "test_helper"

class ServiceProvidersControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get service_provider_path(service_providers(:one))

    assert_redirected_to login_path
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
end
