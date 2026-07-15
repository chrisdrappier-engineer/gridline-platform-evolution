class ServiceRequestShowPage
  QUOTE_TERMS = [
    "Approval authorizes Gridline and the assigned service provider to proceed with the described work up to the quoted amount.",
    "Quotes are based on information available before service begins.",
    "If material site conditions, concealed damage, parts requirements, safety constraints, or other facts are discovered during service, Gridline may amend the quote and request approval before proceeding beyond the approved scope."
  ].join(" ")

  attr_reader :service_request, :quote_form, :cost_form, :assignable_service_providers

  def initialize(service_request:, quote_form:, cost_form:, assignable_service_providers:, view_context:)
    @service_request = service_request
    @quote_form = quote_form
    @cost_form = cost_form
    @assignable_service_providers = assignable_service_providers
    @view = view_context
  end

  def title
    service_request.title
  end

  def eyebrow
    service_request.customer_site.customer.name
  end

  def header_actions
    actions = [ViewAction.link("Back to Requests", view.service_requests_path)]
    actions << ViewAction.link("Edit Request", view.edit_service_request_path(service_request)) if can_update_request?
    actions << ViewAction.button("Triage", view.triage_service_request_path(service_request), method: :patch) if can_triage_request?
    actions << ViewAction.button("Verify Completion", view.verify_completion_service_request_path(service_request), method: :patch) if can_verify_completion?
    actions
  end

  def request_rows
    [
      DetailRow.new("Status", status_pill(service_request.status)),
      DetailRow.new("Priority", priority_pill(service_request.priority)),
      DetailRow.new("Reported", long_time(service_request.reported_at)),
      DetailRow.new("Assigned Dispatcher", service_request.assigned_dispatcher&.name || "Unassigned"),
      DetailRow.new("Provider", service_request.service_provider.name),
      DetailRow.new("Assigned", optional_time(service_request.assigned_at, "Not assigned")),
      DetailRow.new("Provider Responded", optional_time(service_request.provider_responded_at, "No response recorded")),
      DetailRow.new("Scheduled", optional_time(service_request.scheduled_at, "Not scheduled")),
      DetailRow.new("Provider Work Complete", optional_time(service_request.provider_work_completed_at, "No")),
      DetailRow.new("Resolved", optional_time(service_request.resolved_at, "Not resolved")),
      DetailRow.new("Completion Verified", completion_verification),
      canceled_row
    ].compact
  end

  def site_rows
    site = service_request.customer_site

    [
      DetailRow.new("Location", site.name),
      DetailRow.new("Address", address_block(site)),
      DetailRow.new("Created By", service_request.created_by.name)
    ]
  end

  def metrics
    [
      MetricCard.new("Provider Response Time", view.format_duration_seconds(service_request.provider_response_seconds)),
      MetricCard.new("Provider Completion Time", view.format_duration_seconds(service_request.provider_completion_seconds)),
      MetricCard.new("Resolution Time", view.format_duration_seconds(service_request.resolution_seconds)),
      MetricCard.new("Verification Lag", view.format_duration_seconds(service_request.verification_lag_seconds))
    ]
  end

  def description
    service_request.description
  end

  def provider_response_sections
    [
      DetailRow.new("Actions Taken", service_request.provider_response_summary.presence),
      DetailRow.new("Follow-Up Requirements", service_request.follow_up_notes.presence)
    ].select(&:value)
  end

  def render_provider_response?
    provider_response_sections.any?
  end

  def section_partials
    [
      provider_response_section_partial,
      quote_section_partial,
      cost_section_partial,
      assignment_section_partial,
      response_section_partial
    ].compact
  end

  def provider_response_section_partial
    "service_requests/show/provider_response_section" if render_provider_response?
  end

  def quote_section_partial
    "service_requests/show/quote_section" if render_quote_section?
  end

  def cost_section_partial
    "service_requests/show/cost_section" if render_cost_section?
  end

  def assignment_section_partial
    "service_requests/show/assignment_section" if render_assignment_form?
  end

  def response_section_partial
    "service_requests/show/response_section" if render_response_form?
  end

  def render_quote_section?
    can_read_quotes?
  end

  def quote
    service_request.service_request_quote
  end

  def quote_rows
    return [] unless quote

    [
      DetailRow.new("Status", status_pill(quote.status)),
      DetailRow.new("Quoted Amount", money(quote.amount_cents, currency: quote.currency)),
      DetailRow.new("Approval Required", quote.approval_required? ? "Yes" : "No"),
      DetailRow.new("Description", formatted_text(quote.description)),
      approved_quote_row,
      rejected_quote_row,
      amended_quote_row,
      approval_notes_row
    ].compact
  end

  def quote_terms
    QUOTE_TERMS
  end

  def quote_actions
    return [] unless quote&.pending_approval?

    [
      approve_quote_action,
      reject_quote_action
    ].compact
  end

  def render_amend_quote_form?
    quote.present? && view.can?("service_request_quotes", "update", quote)
  end

  def render_new_quote_form?
    quote.blank? && view.can?("service_request_quotes", "create", service_request)
  end

  def quote_empty_message
    "No quote has been submitted for this request."
  end

  def quote_state_partial
    return "service_requests/show/existing_quote" if quote.present?
    return "service_requests/show/new_quote_form" if render_new_quote_form?

    "service_requests/show/quote_empty"
  end

  def amend_quote_partial
    render_amend_quote_form? ? "service_requests/show/amend_quote_form" : "service_requests/show/empty"
  end

  def render_cost_section?
    view.can?("service_request_costs", "read", service_request)
  end

  def actual_cost_summary
    summary = "Actual total: #{money(service_request.actual_cost_total_cents)}"
    variance = service_request.quote_to_actual_variance_cents
    return summary unless variance

    "#{summary} | Quote variance: #{money(variance)}"
  end

  def cost_rows
    service_request.service_request_costs.map do |cost|
      {
        category: cost.category.humanize,
        amount: money(cost.amount_cents, currency: cost.currency),
        incurred_on: view.l(cost.incurred_on, format: :long),
        recorded_by: cost.recorded_by.name,
        description: cost.description.presence || "No description",
        action: edit_cost_action(cost)
      }
    end
  end

  def render_cost_form?
    view.can?("service_request_costs", "create", service_request)
  end

  def cost_state_partial
    cost_rows.any? ? "service_requests/show/cost_table" : "service_requests/show/cost_empty"
  end

  def cost_form_partial
    render_cost_form? ? "service_requests/show/cost_form" : "service_requests/show/empty"
  end

  def cost_categories
    ServiceRequestCost::CATEGORIES.map { |category| [category.humanize, category] }
  end

  def render_assignment_form?
    view.can?("service_requests", "assign", service_request)
  end

  def render_response_form?
    view.can?("service_requests", "respond", service_request)
  end

  private

  attr_reader :view

  def can_update_request?
    view.can?("service_requests", "update", service_request)
  end

  def can_triage_request?
    service_request.status == "new" && view.can?("service_requests", "triage", service_request)
  end

  def can_verify_completion?
    service_request.status == "resolved" &&
      !service_request.completion_verified? &&
      view.can?("service_requests", "verify_completion", service_request)
  end

  def can_read_quotes?
    view.can?("service_request_quotes", "read", service_request)
  end

  def status_pill(status)
    view.tag.span(status.humanize, class: "status-pill status-#{status}")
  end

  def priority_pill(priority)
    view.tag.span(priority.humanize, class: "priority-pill priority-#{priority}")
  end

  def long_time(value)
    view.l(value, format: :long)
  end

  def optional_time(value, fallback)
    value.present? ? long_time(value) : fallback
  end

  def completion_verification
    return "Not verified" unless service_request.completion_verified?

    value = long_time(service_request.completion_verified_at)
    verifier = service_request.completion_verified_by
    return value unless verifier

    "#{value} by #{verifier.name}"
  end

  def canceled_row
    return unless service_request.canceled_at.present?

    DetailRow.new("Canceled", long_time(service_request.canceled_at))
  end

  def address_block(site)
    lines = [
      site.address_line_1,
      site.address_line_2.presence,
      "#{site.city}, #{site.state} #{site.postal_code}"
    ].compact

    view.safe_join(lines, view.tag.br)
  end

  def formatted_text(value)
    view.simple_format(value)
  end

  def money(amount_cents, currency: "USD")
    view.format_money_cents(amount_cents, currency: currency)
  end

  def approved_quote_row
    return unless quote.approved_at.present?

    value = long_time(quote.approved_at)
    value = "#{value} by #{quote.approved_by.name}" if quote.approved_by.present?
    DetailRow.new("Approved", value)
  end

  def rejected_quote_row
    return unless quote.rejected_at.present?

    DetailRow.new("Rejected", "#{long_time(quote.rejected_at)} by #{quote.rejected_by.name}")
  end

  def amended_quote_row
    return unless quote.amended_at.present?

    DetailRow.new(
      "Amended",
      view.safe_join(
        [
          "#{long_time(quote.amended_at)} by #{quote.amended_by.name}",
          "Original amount: #{money(quote.original_amount_cents, currency: quote.currency)}",
          formatted_text(quote.amendment_reason)
        ],
        view.tag.br
      )
    )
  end

  def approval_notes_row
    return unless quote.approval_notes.present?

    DetailRow.new("Approval Notes", formatted_text(quote.approval_notes))
  end

  def approve_quote_action
    return unless view.can?("service_request_quotes", "approve", quote)

    ViewAction.button("Approve Quote", view.approve_service_request_service_request_quote_path(service_request), method: :patch)
  end

  def reject_quote_action
    return unless view.can?("service_request_quotes", "reject", quote)

    ViewAction.button("Reject Quote", view.reject_service_request_service_request_quote_path(service_request), method: :patch, style: "secondary-button")
  end

  def edit_cost_action(cost)
    return unless view.can?("service_request_costs", "update", cost)

    ViewAction.link("Edit", view.edit_service_request_service_request_cost_path(service_request, cost), style: nil)
  end
end
