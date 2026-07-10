require "test_helper"

class CustomerSiteTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert customer_sites(:one).valid?
  end

  test "requires customer" do
    site = customer_sites(:one)
    site.customer = nil

    assert_not site.valid?
    assert_includes site.errors[:customer], "must exist"
  end

  test "requires creator" do
    site = customer_sites(:one)
    site.created_by = nil

    assert_not site.valid?
    assert_includes site.errors[:created_by], "must exist"
  end

  test "requires address fields" do
    site = customer_sites(:one)
    site.address_line_1 = nil
    site.city = nil
    site.state = nil
    site.postal_code = nil

    assert_not site.valid?
    assert_includes site.errors[:address_line_1], "can't be blank"
    assert_includes site.errors[:city], "can't be blank"
    assert_includes site.errors[:state], "can't be blank"
    assert_includes site.errors[:postal_code], "can't be blank"
  end

  test "requires supported site status" do
    site = customer_sites(:one)
    site.site_status = "unknown"

    assert_not site.valid?
    assert_includes site.errors[:site_status], "is not included in the list"
  end

  test "cannot be destroyed while it has service requests" do
    site = customer_sites(:one)

    assert_not site.destroy
    assert site.persisted?
    assert site.errors.any?
  end
end
