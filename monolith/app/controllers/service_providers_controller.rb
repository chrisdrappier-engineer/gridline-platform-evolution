class ServiceProvidersController < ApplicationController
  before_action :set_service_provider, only: %i[show edit update]

  def index
    relation = authorized_scope(
      "service_providers",
      "read",
      ServiceProvider.left_joins(:created_by).includes(:created_by)
    )

    @service_providers_table = ServiceProvidersTable.build(
      relation: relation,
      params: service_providers_table_params,
      path: service_providers_path,
      paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
    )
    @service_providers = @service_providers_table.rows
    @page_actions = [
      ViewAction.link("View Requests", service_requests_path),
      new_service_provider_action
    ].compact
  end

  def show
    authorize!("service_providers", "read", @service_provider)
    @page_actions = [
      ViewAction.link("Back to Providers", service_providers_path),
      edit_service_provider_action(@service_provider)
    ].compact

    @service_requests = authorized_scope(
      "service_requests",
      "read",
      @service_provider.service_requests.includes(:assigned_dispatcher, :service_provider, customer_site: :customer)
    ).order(reported_at: :desc)
    @performance_summary = ProviderPerformanceSummary.new(@service_requests)
    @service_request_actions = [new_service_request_action].compact
  end

  def new
    authorize!("service_providers", "create")
    @service_provider = ServiceProvider.new(provider_type: "vendor_partner", status: "active")
  end

  def create
    authorize!("service_providers", "create")

    @service_provider = ServiceProvider.new(service_provider_params)
    @service_provider.created_by = current_user

    if @service_provider.save
      redirect_to @service_provider, notice: "Service provider created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize!("service_providers", "update", @service_provider)
  end

  def update
    authorize!("service_providers", "update", @service_provider)

    if @service_provider.update(service_provider_params)
      redirect_to @service_provider, notice: "Service provider updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_service_provider
    @service_provider = ServiceProvider.includes(:created_by).find(params[:id])
  end

  def service_providers_table_params
    params.fetch(:service_providers, {}).permit(:search, :provider_type, :status, :sort, :direction, :page, :limit).to_h
  end

  def service_provider_params
    params.require(:service_provider).permit(:name, :provider_type, :status)
  end

  def new_service_provider_action
    return unless permitted?("service_providers", "create")

    ViewAction.link("New Service Provider", new_service_provider_path, style: "primary-button")
  end

  def edit_service_provider_action(service_provider)
    return unless can?("service_providers", "update", service_provider)

    ViewAction.link("Edit Provider", edit_service_provider_path(service_provider), style: "primary-button")
  end

  def new_service_request_action
    return unless permitted?("service_requests", "create")

    ViewAction.link("New Request", new_service_request_path(service_provider_id: @service_provider.id))
  end
end
