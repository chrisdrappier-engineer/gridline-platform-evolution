module Admin
  class RoleAssignmentsTable
    PAGE_SIZE = 20
    PAGE_SIZE_OPTIONS = [10, 20, 30].freeze

    def self.build(relation:, params:, path:, paginator:)
      DataTable::Query.new(
        key: :role_assignments,
        path: path,
        relation: relation,
        params: params,
        columns: columns,
        filters: filters,
        default_sort: { sort: "user", direction: "asc" },
        page_size: PAGE_SIZE,
        page_size_options: PAGE_SIZE_OPTIONS,
        paginator: paginator,
        empty_title: "No role assignments found",
        empty_message: "Adjust the search or filters to find matching assignments."
      ).call
    end

    def self.columns
      [
        DataTable::Column.new(key: :user, sortable_by: "users.name", searchable_by: ["users.name", "users.email"]),
        DataTable::Column.new(key: :role, sortable_by: "roles.name", searchable_by: ["roles.name", "roles.key"]),
        DataTable::Column.new(key: :scope, searchable_by: ["user_role_assignments.resource_type", "user_role_assignments.resource_id::text"])
      ]
    end

    def self.filters
      [
        DataTable::Filter.new(
          key: :role_id,
          label: "Role",
          field: :role_id,
          options: ->(context) { context.fetch(:roles).map { |role| [role.name, role.id] } }
        ),
        DataTable::Filter.new(
          key: :scope,
          field: :resource_type,
          options: [["Global", "global"], ["Customer", "Customer"], ["Customer Site", "CustomerSite"], ["Service Provider", "ServiceProvider"]],
          apply: ->(scope, value) { value == "global" ? scope.where(resource_type: nil) : scope.where(resource_type: value) }
        )
      ]
    end
  end
end
