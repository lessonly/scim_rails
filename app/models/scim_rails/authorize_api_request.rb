module ScimRails
  class AuthorizeApiRequest

    def initialize(subdomain:, api_key:)
      @subdomain = subdomain
      @api_key = api_key

      raise ScimRails::ExceptionHandler::MissingCredentials if subdomain.blank? || api_key.blank?
    end

    def company
      company = find_company
      authorize(company)
      company
    end

    private

    attr_reader :subdomain
    attr_reader :api_key

    def find_company
      @company ||= Company.find_by!(subdomain: subdomain)

    rescue ActiveRecord::RecordNotFound
      raise ScimRails::ExceptionHandler::InvalidCredentials
    end

    def authorize(company)
      authorized = ActiveSupport::SecurityUtils::secure_compare(company.api_key, api_key)
      raise ScimRails::ExceptionHandler::InvalidCredentials unless authorized
    end
  end
end
