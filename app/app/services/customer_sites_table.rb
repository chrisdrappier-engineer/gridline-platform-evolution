class CustomerSitesTable
  PAGE_SIZE = 20
  PAGE_SIZE_OPTIONS = [10, 20, 30].freeze

  def self.build(relation:, params:, path:, paginator:)
    DataTable::Query.new(
      key: :customer_sites,
      path: path,
      relation: relation,
      params: params,
      columns: columns,
      filters: filters,
      default_sort: { sort: "site", direction: "asc" },
      page_size: PAGE_SIZE,
      page_size_options: PAGE_SIZE_OPTIONS,
      paginator: paginator,
      empty_title: "No sites found",
      empty_message: "Adjust the search or filters to find matching sites."
    ).call
  end

  def self.columns
    [
      DataTable::Column.new(key: :site, label: "Site", sortable_by: "customer_sites.name", searchable_by: "customer_sites.name"),
      DataTable::Column.new(key: :customer, sortable_by: "customers.name", searchable_by: "customers.name"),
      DataTable::Column.new(key: :status, sortable_by: "customer_sites.site_status", searchable_by: "customer_sites.site_status"),
      DataTable::Column.new(key: :location, sortable_by: "customer_sites.city", searchable_by: ["customer_sites.city", "customer_sites.state", "customer_sites.postal_code"]),
      DataTable::Column.new(key: :actions)
    ]
  end

  def self.filters
    [
      DataTable::Filter.new(
        key: :site_status,
        label: "Status",
        field: :site_status,
        options: CustomerSite::SITE_STATUSES.map { |status| [status.humanize, status] }
      )
    ]
  end
end
