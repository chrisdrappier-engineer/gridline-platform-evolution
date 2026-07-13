module Admin
  class UsersController < ApplicationController
    def index
      authorize!("users", "read")

      @users = User.includes(:roles).order(:email)
    end
  end
end
