# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScimRails::ScimGroupsController, type: :request do
  let(:company) { create(:company) }
  let(:credentials) do
    Base64.encode64("#{company.subdomain}:#{company.api_token}")
  end
  let(:authorization) { "Basic #{credentials}" }

  def post_request(content_type = "application/scim+json")
    post "/scim/v2/Groups",
         params: {
           displayName: "Dummy Group",
           members: []
         }.to_json,
         headers: {
           Authorization: authorization,
           'Content-Type': content_type
         }
  end

  describe "Content-Type" do
    it "accepts scim+json" do
      expect(company.groups.count).to eq 0

      post_request("application/scim+json")

      expect(request.params).to include :displayName
      expect(response.status).to eq 201
      expect(response.media_type).to eq "application/scim+json"
      expect(company.groups.count).to eq 1
    end

    it "can not parse unfamiliar content types" do
      expect(company.groups.count).to eq 0

      post_request("text/csv")

      expect(request.params).not_to include :displayName
      expect(response.status).to eq 422
      expect(company.groups.count).to eq 0
    end
  end

  context "OAuth Bearer Authorization" do
    context "with valid token" do
      let(:authorization) { "Bearer #{company.api_token}" }

      it "supports OAuth bearer authorization and succeeds" do
        expect { post_request }.to change(company.groups, :count).from(0).to(1)

        expect(response.status).to eq 201
      end
    end

    context "with invalid token" do
      let(:authorization) { "Bearer #{SecureRandom.hex}" }

      it "The request fails" do
        expect { post_request }.not_to change(company.groups, :count)

        expect(response.status).to eq 401
      end
    end
  end
end
