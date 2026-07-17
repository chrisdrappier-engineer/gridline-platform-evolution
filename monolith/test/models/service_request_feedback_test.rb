require "test_helper"

class ServiceRequestFeedbackTest < ActiveSupport::TestCase
  test "rating options expose five human readable choices" do
    assert_equal 5, ServiceRequestFeedback.rating_options.size
    assert_includes ServiceRequestFeedback.rating_options, ["5 - Excellent", 5]
  end

  test "requires rating in supported range" do
    feedback = service_request_feedbacks(:one)
    feedback.rating = 6

    assert_not feedback.valid?
    assert_includes feedback.errors[:rating], "is not included in the list"
  end

  test "requires feedback text" do
    feedback = service_request_feedbacks(:one)
    feedback.feedback = ""

    assert_not feedback.valid?
    assert_includes feedback.errors[:feedback], "can't be blank"
  end

  test "allows one feedback record per service request" do
    duplicate = service_request_feedbacks(:one).dup

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:service_request_id], "has already been taken"
  end
end
