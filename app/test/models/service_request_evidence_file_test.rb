require "test_helper"

class ServiceRequestEvidenceFileTest < ActiveSupport::TestCase
  test "category options include supported evidence categories" do
    assert_includes ServiceRequestEvidenceFile::CATEGORIES, "before_photo"
    assert_includes ServiceRequestEvidenceFile::CATEGORIES, "invoice"
    assert_includes ServiceRequestEvidenceFile::CATEGORIES, "diagnostic_report"
  end

  test "accept attribute excludes deferred file types" do
    accept_attribute = ServiceRequestEvidenceFile.accept_attribute

    assert_includes accept_attribute, ".png"
    assert_includes accept_attribute, ".pdf"
    assert_includes accept_attribute, ".csv"
    assert_not_includes accept_attribute, ".mp4"
    assert_not_includes accept_attribute, ".docx"
  end

  test "limit messages provide recovery instructions" do
    assert_match(/compressing the image/, ServiceRequestEvidenceFile.limit_message_for("image/png"))
    assert_match(/splitting the document/, ServiceRequestEvidenceFile.limit_message_for("application/pdf"))
    assert_match(/splitting the file/, ServiceRequestEvidenceFile.limit_message_for("text/csv"))
  end
end
