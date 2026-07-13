module Admin
  class RoleAssignmentsController < ApplicationController
    def index
      authorize!("user_role_assignments", "read")

      @role_assignments = UserRoleAssignment
                          .joins(:user, :role)
                          .includes(:user, :role)
                          .order("users.email", "roles.key")
    end
  end
end
