module Admin
  class RolePermissionsController < ApplicationController
    def index
      authorize!("role_permissions", "read")

      @roles = Role.includes(:permissions).order(:key)
      @permissions = Permission.order(:resource, :action)
    end
  end
end
