class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    email = params.dig(:session, :email).to_s.strip.downcase
    password = params.dig(:session, :password).to_s
    allowed_email = ENV["GRIDLINE_STUB_USER_EMAIL"].presence
    expected_password = ENV.fetch("GRIDLINE_STUB_USER_PASSWORD", "gridline")

    if password == expected_password && allowed_email_allows?(allowed_email, email)
      user = User.find_by(email: email, active: true)
      if user
        session[:user_id] = user.id
        redirect_to dashboard_path, notice: "Signed in as #{user.name}."
        return
      end
    end

    redirect_to login_path, alert: "Invalid stub credentials."
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Signed out."
  end

  private

  def allowed_email_allows?(allowed_email, email)
    allowed_email.blank? || allowed_email.downcase == email
  end
end
