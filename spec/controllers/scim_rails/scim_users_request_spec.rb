require "spec_helper"

RSpec.describe ScimRails::ScimUsersController, type: :request do
  let(:company) { create(:company) }
  let(:credentials) { Base64::encode64("#{company.subdomain}:#{company.api_token}") }
  let(:authorization) { "Basic #{credentials}" }

  def post_request(content_type)
    # params need to be transformed into a string to test if they are being parsed by Rack

    post "/scim_rails/scim/v2/Users",
    params: {
      name: {
        givenName: "New",
        familyName: "User"
      },
      emails: [
        {
          value: "new@example.com"
        }
      ]
    }.to_json,
    headers: {
      'Authorization': authorization,
      'Content-Type': content_type
    }
  end

  describe "Content-Type" do
    it "accepts scim+json" do
      expect(company.users.count).to eq 0

      post_request("application/scim+json")

      expect(request.params).to include :name
      expect(response.status).to eq 201
      expect(response.content_type).to eq "application/scim+json"
      expect(company.users.count).to eq 1
    end

    it "can not parse unfamiliar content types" do
      expect(company.users.count).to eq 0

      post_request("invalid_type")

      expect(request.params).not_to include :name
      expect(response.status).to eq 422
      expect(company.users.count).to eq 0
    end
  end
end
