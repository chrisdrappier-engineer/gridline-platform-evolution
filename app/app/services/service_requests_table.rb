class ServiceRequestsTable
  PAGE_SIZE = 25

  def self.build(relation:, params:, path:, paginator:)
    DataTable::Query.new(
      key: :service_requests,
      path: path,
      relation: relation,
      params: params,
      columns: columns,
      filters: filters,
      default_sort: { sort: "reported_at", direction: "desc" },
      page_size: PAGE_SIZE,
      paginator: paginator,
      empty_title: "No service requests found",
      empty_message: "Adjust the search or filters to find matching requests."
    ).call
  end

  def self.columns
    [
      DataTable::Column.new(
        key: :request,
        label: "Request",
        sortable_by: "service_requests.title",
        searchable_by: ["service_requests.title", "service_requests.description", "service_providers.name"]
      ),
      DataTable::Column.new(
        key: :site,
        label: "Site",
        sortable_by: "customer_sites.name",
        searchable_by: ["customer_sites.name", "customers.name"]
      ),
      DataTable::Column.new(
        key: :status,
        sortable_by: "service_requests.status",
        searchable_by: "service_requests.status"
      ),
      DataTable::Column.new(
        key: :priority,
        sortable_by: "service_requests.priority",
        searchable_by: "service_requests.priority"
      ),
      DataTable::Column.new(
        key: :dispatcher
      ),
      DataTable::Column.new(
        key: :reported_at,
        label: "Reported",
        sortable_by: "service_requests.reported_at"
      )
    ]
  end

  def self.filters
    [
      DataTable::Filter.new(
        key: :customer_site_id,
        label: "Site",
        field: :customer_site_id,
        options: ->(context) { context.fetch(:filter_sites) }
      ),
      DataTable::Filter.new(
        key: :status,
        field: :status,
        options: ServiceRequest::STATUSES.map { |status| [status.humanize, status] }
      ),
      DataTable::Filter.new(
        key: :priority,
        field: :priority,
        options: ServiceRequest::PRIORITIES.map { |priority| [priority.humanize, priority] }
      )
    ]
  end
end
