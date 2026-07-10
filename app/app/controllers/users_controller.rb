class UsersController < ApplicationController
  def show
    @dispatcher = User.find(params[:id])
    @assigned_service_requests = @dispatcher
                                 .assigned_service_requests
                                 .includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
                                 .order(reported_at: :desc)
  end
end
