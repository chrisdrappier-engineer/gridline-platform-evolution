module ApplicationHelper
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
end
