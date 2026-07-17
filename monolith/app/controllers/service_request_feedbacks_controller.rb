class ServiceRequestFeedbacksController < ApplicationController
  before_action :set_service_request

  def create
    authorize!("service_request_feedbacks", "create", @service_request)
    return unless resolved_request?

    feedback = @service_request.build_service_request_feedback(feedback_params.merge(submitted_by: current_user))
    feedback.save!
    redirect_to @service_request, notice: "Service feedback submitted.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @service_request, alert: error.record.errors.full_messages.to_sentence
  end

  def update
    feedback = @service_request.service_request_feedback
    authorize!("service_request_feedbacks", "update", feedback)
    return unless resolved_request?

    feedback.update!(feedback_params)
    redirect_to @service_request, notice: "Service feedback updated.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @service_request, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_service_request
    @service_request = ServiceRequest.find(params[:service_request_id])
  end

  def feedback_params
    params.require(:service_request_feedback).permit(:rating, :feedback, :follow_up_needed)
  end

  def resolved_request?
    return true if @service_request.status == "resolved"

    redirect_to @service_request, alert: "Feedback can only be submitted for resolved requests."
    false
  end
end
