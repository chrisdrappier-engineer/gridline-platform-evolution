require "test_helper"

class ServiceRequestNoteTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert service_request_notes(:one).valid?
  end

  test "requires supported note type" do
    note = service_request_notes(:one)
    note.note_type = "unsupported"

    assert_not note.valid?
    assert_includes note.errors[:note_type], "is not included in the list"
  end

  test "requires supported visibility" do
    note = service_request_notes(:one)
    note.visibility = "public"

    assert_not note.valid?
    assert_includes note.errors[:visibility], "is not included in the list"
  end

  test "prevents customer-side users from creating internal notes" do
    note = ServiceRequestNote.new(
      service_request: service_requests(:one),
      author: users(:three),
      note_type: "general",
      visibility: "internal",
      body: "Customer-side user should not create internal notes."
    )

    assert_not note.valid?
    assert_includes note.errors[:visibility], "is not available for this user"
  end

  test "returns role-specific visible visibilities" do
    assert_equal ServiceRequestNote::VISIBILITIES, ServiceRequestNote.visible_visibilities_for(users(:one))
    assert_equal %w[customer_visible shared], ServiceRequestNote.visible_visibilities_for(users(:three))
    assert_equal %w[provider_visible shared], ServiceRequestNote.visible_visibilities_for(users(:five))
  end
end
