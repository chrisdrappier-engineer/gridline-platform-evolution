module ApplicationHelper
  def page_title(default_title = "Gridline Operations")
    content_for(:title).presence || default_title
  end

  def form_errors_for(record)
    return unless record.errors.any?

    render("shared/form_errors", record: record)
  end

  def submit_label(record, create:, update:)
    record.persisted? ? update : create
  end

  def active_status_label(record)
    record.active? ? "Active" : "Inactive"
  end

  def resolution_percentage_label(summary)
    percentage = summary.resolution_percentage
    percentage ? "#{percentage}%" : "Not enough data"
  end

  def customer_site_address(site)
    lines = [
      site.address_line_1,
      site.address_line_2.presence,
      "#{site.city}, #{site.state} #{site.postal_code}"
    ].compact

    safe_join(lines, tag.br)
  end

  def facility_manager_names(site)
    managers = site.facility_managers.order(:name)
    return "None assigned" unless managers.any?

    managers.map(&:name).to_sentence
  end

  def role_names(user)
    user.roles.map(&:name).sort.join(", ")
  end

  def assignment_resource_label(assignment)
    return "Global" unless assignment.resource

    "#{assignment.resource_type}: #{assignment.resource.try(:name) || assignment.resource_id}"
  end

  def permission_matrix_badge(role, permission)
    allowed = role.permissions.any? { |role_permission| role_permission.id == permission.id }
    label = allowed ? "Allowed" : "Not allowed"
    class_name = allowed ? "matrix-allowed" : "matrix-denied"
    verb = allowed ? "can" : "cannot"

    tag.span(label, class: class_name, aria: { label: "#{role.name} #{verb} #{permission.action} #{permission.resource}" })
  end

  def facility_manager_dashboard_action(managed_sites)
    if managed_sites.one?
      ViewAction.link("Create Request", new_service_request_path(customer_site_id: managed_sites.first.id), style: "primary-button")
    else
      ViewAction.link("Choose Site", customer_sites_path)
    end
  end

  def optional_tag(name, content = nil, **options)
    return if content.blank?

    tag.public_send(name, content, **options)
  end

  def render_when(condition, partial, locals = {})
    render(partial, locals) if condition
  end

  def render_optional_action(action)
    render("shared/action", action: action) if action
  end

  def render_collection_state(collection, present_partial:, empty_title:, empty_message:, locals: {})
    if collection.any?
      render(present_partial, locals)
    else
      render("shared/empty_state", title: empty_title, message: empty_message)
    end
  end

  def action_partial(action)
    action.button? ? "shared/button_action" : "shared/link_action"
  end

  def format_money_cents(amount_cents, currency: "USD")
    return "Not recorded" if amount_cents.nil?

    number_to_currency(amount_cents / 100.0, unit: currency == "USD" ? "$" : "#{currency} ")
  end

  def format_duration_seconds(seconds)
    return "Not enough data" if seconds.nil?

    distance_of_time_in_words(seconds.seconds)
  end

  def navigation_sections
    [
      {
        label: "Operations",
        links: [
          ["Dashboard", dashboard_path, true],
          ["Requests", service_requests_path, permitted?("service_requests", "read")],
          ["New Request", new_service_request_path, permitted?("service_requests", "create")],
          ["Customers", customers_path, permitted?("customers", "read")],
          ["Sites", customer_sites_path, permitted?("customer_sites", "read")],
          ["Service Providers", service_providers_path, permitted?("service_providers", "read")]
        ]
      },
      {
        label: "Administration",
        links: [
          ["Permission Matrix", admin_role_permissions_path, permitted?("role_permissions", "read")],
          ["Role Assignments", admin_role_assignments_path, permitted?("user_role_assignments", "read")],
          ["Users", admin_users_path, permitted?("users", "read")]
        ]
      }
    ].filter_map do |section|
      links = section.fetch(:links).select { |_label, _path, visible| visible }
      next if links.empty?

      section.merge(links: links)
    end
  end

  def application_body_options
    return {} unless signed_in?

    { data: { controller: "navigation-panel" } }
  end

  def application_header_partial
    signed_in? ? "layouts/signed_in_header" : "layouts/anonymous_header"
  end

  def application_navigation_partial
    signed_in? ? "layouts/side_navigation" : "layouts/empty_navigation"
  end

  def application_frame_options
    return { class: "app-frame" } unless signed_in?

    {
      class: "app-frame app-frame-with-navigation",
      data: { navigation_panel_target: "frame" }
    }
  end
end
