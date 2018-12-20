module AuthHelper
  def http_login(company)
    user = company.subdomain
    password = company.api_token
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,password)
  end
end
