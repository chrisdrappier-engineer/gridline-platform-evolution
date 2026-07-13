class CustomersTable
  PAGE_SIZE = 20
  PAGE_SIZE_OPTIONS = [10, 20, 30].freeze

  def self.build(relation:, params:, path:, paginator:)
    DataTable::Query.new(
      key: :customers,
      path: path,
      relation: relation,
      params: params,
      columns: columns,
      filters: filters,
      default_sort: { sort: "customer", direction: "asc" },
      page_size: PAGE_SIZE,
      page_size_options: PAGE_SIZE_OPTIONS,
      paginator: paginator,
      empty_title: "No customers found",
      empty_message: "Adjust the search or filters to find matching customers."
    ).call
  end

  def self.columns
    [
      DataTable::Column.new(key: :customer, label: "Customer", sortable_by: "customers.name", searchable_by: "customers.name"),
      DataTable::Column.new(key: :status, sortable_by: "customers.account_status", searchable_by: "customers.account_status"),
      DataTable::Column.new(key: :industry, sortable_by: "customers.industry", searchable_by: "customers.industry"),
      DataTable::Column.new(key: :created_by, label: "Created By", sortable_by: "users.name", searchable_by: "users.name")
    ]
  end

  def self.filters
    [
      DataTable::Filter.new(
        key: :account_status,
        label: "Status",
        field: :account_status,
        options: Customer::ACCOUNT_STATUSES.map { |status| [status.humanize, status] }
      )
    ]
  end
end
