class ServiceRequestFormPage
  attr_reader :service_request, :customer_sites, :service_providers, :context_customer, :follow_up_to_service_request

  def initialize(service_request:, customer_sites:, service_providers:, context_customer:, follow_up_to_service_request: nil)
    @service_request = service_request
    @customer_sites = customer_sites
    @service_providers = service_providers
    @context_customer = context_customer
    @follow_up_to_service_request = follow_up_to_service_request
  end

  def context_partial
    return "service_requests/forms/follow_up_context" if follow_up_to_service_request
    return "service_requests/forms/selected_site_context" if service_request.customer_site
    return "service_requests/forms/selected_customer_context" if context_customer

    "service_requests/forms/empty"
  end

  def site_field_partial
    locked_site? ? "service_requests/forms/hidden_site_field" : "service_requests/forms/selectable_site_field"
  end

  def provider_field_partial
    service_providers.any? ? "service_requests/forms/provider_select_field" : "service_requests/forms/provider_routing_context"
  end

  def site_choice_label(site)
    "#{site.customer.name} - #{site.name}"
  end

  def site_field_hint
    return unless context_customer

    "Site choices are limited to the selected customer."
  end

  def follow_up_original_path
    Rails.application.routes.url_helpers.service_request_path(follow_up_to_service_request)
  end

  private

  def locked_site?
    service_request.customer_site && customer_sites.one?
  end
end
