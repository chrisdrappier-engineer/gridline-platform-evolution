class ServiceRequestFeedback < ApplicationRecord
  RATINGS = (1..5).freeze

  belongs_to :service_request, inverse_of: :service_request_feedback
  belongs_to :submitted_by,
             class_name: "User",
             inverse_of: :submitted_service_request_feedbacks

  validates :rating, presence: true, inclusion: { in: RATINGS }
  validates :feedback, presence: true
  validates :service_request_id, uniqueness: true

  def self.rating_options
    RATINGS.map { |rating| ["#{rating} - #{rating_label(rating)}", rating] }
  end

  def self.rating_label(rating)
    {
      1 => "Poor",
      2 => "Needs improvement",
      3 => "Satisfactory",
      4 => "Good",
      5 => "Excellent"
    }.fetch(rating)
  end

  def rating_label
    self.class.rating_label(rating)
  end
end
