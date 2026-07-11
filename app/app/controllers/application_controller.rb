class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :signed_in?

  rescue_from Authorization::AccessDenied, with: :deny_access

  private

  def authorize!(resource, action, target = nil)
    Authorization.authorize!(current_user, resource: resource, action: action, target: target)
  end

  def authorized_scope(resource, action, relation)
    Authorization.accessible_scope(current_user, resource: resource, action: action, relation: relation)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id], active: true)
  end

  def signed_in?
    current_user.present?
  end

  def require_login
    return if signed_in?

    redirect_to login_path, alert: "Sign in to continue."
  end

  def deny_access
    redirect_to dashboard_path, alert: "You are not authorized to access that page."
  end
end
