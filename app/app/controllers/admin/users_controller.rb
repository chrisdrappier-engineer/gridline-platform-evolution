module Admin
  class UsersController < ApplicationController
    def index
      authorize!("users", "read")

      relation = User.left_joins(:roles).includes(:roles).distinct

      @users_table = Admin::UsersTable.build(
        relation: relation,
        params: users_table_params,
        path: admin_users_path,
        paginator: ->(scope, limit:, page:) { pagy(:offset, scope, limit: limit, page: page) }
      )
      @users = @users_table.rows
    end

    private

    def users_table_params
      params.fetch(:users, {}).permit(:search, :role, :active, :sort, :direction, :page, :limit).to_h
    end
  end
end
