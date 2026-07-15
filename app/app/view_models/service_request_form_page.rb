class ServiceRequestFormPage
  attr_reader :service_request, :customer_sites, :service_providers, :context_customer

  def initialize(service_request:, customer_sites:, service_providers:, context_customer:)
    @service_request = service_request
    @customer_sites = customer_sites
    @service_providers = service_providers
    @context_customer = context_customer
  end

  def context_partial
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

  private

  def locked_site?
    service_request.customer_site && customer_sites.one?
  end
end
