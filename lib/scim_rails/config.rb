module ScimRails
  class << self
    def configure
      yield config
    end

    def config
      @_config ||= Config.new
    end
  end

  class Config
    attr_accessor \
      :basic_auth_model,
      :scim_users_model

    def initialize
      @basic_auth_model = "Company"
      @scim_users_model = "User"
    end

    def basic_auth_model
      @basic_auth_model.constantize
    end

    def scim_users_model
      @scim_users_model.constantize
    end
  end
end
