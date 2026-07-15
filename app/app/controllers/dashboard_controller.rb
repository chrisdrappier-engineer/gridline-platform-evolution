class DashboardController < ApplicationController
  def show
    @dashboard_role_key = current_user.dashboard_role_key

    load_common_dashboard_data

    case @dashboard_role_key
    when "admin"
      load_admin_dashboard
      render :admin
    when "facility_manager"
      load_facility_manager_dashboard
      render :facility_manager
    when "customer_contact"
      load_customer_contact_dashboard
      render :customer_contact
    when "service_provider_user"
      load_service_provider_dashboard
      render :service_provider_user
    else
      load_dispatcher_dashboard
      render :dispatcher
    end
  end

  private

  def load_common_dashboard_data
    @readable_requests = authorized_scope(
      "service_requests",
      "read",
      ServiceRequest.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    )
    @open_requests = @readable_requests.where.not(status: %w[resolved canceled])
    @urgent_requests = @readable_requests.where(priority: "urgent").where.not(status: %w[resolved canceled])
    @recent_requests = @readable_requests.order(reported_at: :desc).limit(8)
  end

  def load_dispatcher_dashboard
    @new_requests = @readable_requests.where(status: "new")
    @unassigned_requests = @readable_requests.where(assigned_dispatcher_id: nil)
    @readable_sites = authorized_scope(
      "customer_sites",
      "read",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )
  end

  def load_facility_manager_dashboard
    @managed_sites = authorized_scope(
      "customer_sites",
      "read",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )
    @requests_waiting_verification = @readable_requests.where(status: "resolved")
  end

  def load_customer_contact_dashboard
    @customers = authorized_scope("customers", "read", Customer.order(:name))
    @customer_sites = authorized_scope(
      "customer_sites",
      "read",
      CustomerSite.includes(:customer).order("customers.name", :name).references(:customer)
    )
  end

  def load_service_provider_dashboard
    @service_providers = authorized_scope("service_providers", "read", ServiceProvider.order(:name))
    @response_queue = @readable_requests.where(status: %w[triaged scheduled in_progress])
    @performance_summary = ProviderPerformanceSummary.new(@readable_requests)
  end

  def load_admin_dashboard
    @roles = Role.includes(:permissions).order(:key)
    @permissions = Permission.order(:resource, :action)
    @role_assignments = UserRoleAssignment.joins(:user, :role).includes(:user, :role).order("users.email", "roles.key")
  end
end
