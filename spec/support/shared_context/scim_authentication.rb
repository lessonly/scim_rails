shared_context 'scim_authentication' do
  let(:auth_header) { ActionController::HttpAuthentication::Basic.encode_credentials(company.subdomain, company.api_token) }

  let(:valid_authentication_header) do
    {
      Authorization: auth_header,
      'CONTENT_TYPE': "application/scim+json",
      'ACCEPT': "application/json",
    }
  end

  let(:invalid_authentication_header) do
    {
      Authorization: 'Invalid authorization',
      'CONTENT_TYPE': "application/scim+json",
      'ACCEPT': "application/json",
    }
  end
end
