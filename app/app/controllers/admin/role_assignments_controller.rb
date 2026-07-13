module Admin
  class RoleAssignmentsController < ApplicationController
    def index
      authorize!("user_role_assignments", "read")

      relation = UserRoleAssignment
                 .joins(:user, :role)
                 .includes(:user, :role)

      @roles = Role.order(:name)
      @role_assignments_table = Admin::RoleAssignmentsTable.build(
        relation: relation,
        params: role_assignments_table_params,
        path: admin_role_assignments_path,
        paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
      )
      @role_assignments = @role_assignments_table.rows
    end

    private

    def role_assignments_table_params
      params.fetch(:role_assignments, {}).permit(:search, :role_id, :scope, :sort, :direction, :page, :limit).to_h
    end
  end
end
