module Admin
  class UsersTable
    PAGE_SIZE = 20
    PAGE_SIZE_OPTIONS = [10, 20, 30].freeze

    def self.build(relation:, params:, path:, paginator:)
      DataTable::Query.new(
        key: :users,
        path: path,
        relation: relation,
        params: params,
        columns: columns,
        filters: filters,
        default_sort: { sort: "email", direction: "asc" },
        page_size: PAGE_SIZE,
        page_size_options: PAGE_SIZE_OPTIONS,
        paginator: paginator,
        empty_title: "No users found",
        empty_message: "Adjust the search or filters to find matching users."
      ).call
    end

    def self.columns
      [
        DataTable::Column.new(key: :user, sortable_by: "users.name", searchable_by: "users.name"),
        DataTable::Column.new(key: :email, sortable_by: "users.email", searchable_by: "users.email"),
        DataTable::Column.new(key: :legacy_role, label: "Legacy Role", sortable_by: "users.role", searchable_by: "users.role"),
        DataTable::Column.new(key: :assigned_roles, label: "Assigned Roles", searchable_by: "roles.name"),
        DataTable::Column.new(key: :status)
      ]
    end

    def self.filters
      [
        DataTable::Filter.new(
          key: :role,
          label: "Legacy Role",
          field: :role,
          options: User::ROLES.map { |role| [role.humanize, role] }
        ),
        DataTable::Filter.new(
          key: :active,
          label: "Status",
          field: :active,
          options: [["Active", "true"], ["Inactive", "false"]],
          apply: ->(scope, value) { scope.where(active: ActiveModel::Type::Boolean.new.cast(value)) }
        )
      ]
    end
  end
end
