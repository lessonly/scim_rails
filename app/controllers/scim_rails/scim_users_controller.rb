module ScimRails
  class ScimUsersController < ApplicationController
    def index
      @users = User.last
      scim_response(@users)
    end

    def create
    end

    def show
    end

    def update
    end

    def deprovision
    end

    private

    def scim_response(object, status = :ok)
      render(json: object, status: status)
    end
  end
end
