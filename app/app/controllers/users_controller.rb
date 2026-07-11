class UsersController < ApplicationController
  def show
    @dispatcher = User.find(params[:id])
    @assigned_service_requests = authorized_scope(
      "service_requests",
      "read",
      @dispatcher.assigned_service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)

    raise Authorization::AccessDenied if @assigned_service_requests.empty? && @dispatcher != current_user
  end
end
