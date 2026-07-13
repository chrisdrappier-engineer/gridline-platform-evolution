class ServiceProvidersTable
  PAGE_SIZE = 20
  PAGE_SIZE_OPTIONS = [10, 20, 30].freeze

  def self.build(relation:, params:, path:, paginator:)
    DataTable::Query.new(
      key: :service_providers,
      path: path,
      relation: relation,
      params: params,
      columns: columns,
      filters: filters,
      default_sort: { sort: "provider", direction: "asc" },
      page_size: PAGE_SIZE,
      page_size_options: PAGE_SIZE_OPTIONS,
      paginator: paginator,
      empty_title: "No service providers found",
      empty_message: "Adjust the search or filters to find matching providers."
    ).call
  end

  def self.columns
    [
      DataTable::Column.new(key: :provider, label: "Provider", sortable_by: "service_providers.name", searchable_by: "service_providers.name"),
      DataTable::Column.new(key: :type, sortable_by: "service_providers.provider_type", searchable_by: "service_providers.provider_type"),
      DataTable::Column.new(key: :status, sortable_by: "service_providers.status", searchable_by: "service_providers.status"),
      DataTable::Column.new(key: :created_by, label: "Created By", sortable_by: "users.name", searchable_by: "users.name")
    ]
  end

  def self.filters
    [
      DataTable::Filter.new(
        key: :provider_type,
        label: "Type",
        field: :provider_type,
        options: ServiceProvider::PROVIDER_TYPES.map { |type| [type.humanize, type] }
      ),
      DataTable::Filter.new(
        key: :status,
        field: :status,
        options: ServiceProvider::STATUSES.map { |status| [status.humanize, status] }
      )
    ]
  end
end
