require "test_helper"

class ServiceProviderTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert service_providers(:one).valid?
  end

  test "requires creator" do
    provider = service_providers(:one)
    provider.created_by = nil

    assert_not provider.valid?
    assert_includes provider.errors[:created_by], "must exist"
  end

  test "requires supported provider type" do
    provider = service_providers(:one)
    provider.provider_type = "freelancer"

    assert_not provider.valid?
    assert_includes provider.errors[:provider_type], "is not included in the list"
  end

  test "requires supported status" do
    provider = service_providers(:one)
    provider.status = "paused"

    assert_not provider.valid?
    assert_includes provider.errors[:status], "is not included in the list"
  end

  test "cannot be destroyed while it has service requests" do
    provider = service_providers(:one)

    assert_not provider.destroy
    assert provider.persisted?
    assert provider.errors.any?
  end
end
