module ScimRails
  module Response
    def scim_response(object, status = :ok)
      render(json: object, status: status)
    end
  end
end
