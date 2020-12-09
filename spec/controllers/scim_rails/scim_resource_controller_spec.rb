require "spec_helper"

RSpec.describe ScimRails::ScimResourceController, type: :controller do
  include AuthHelper

  routes { ScimRails::Engine.routes }

  describe "resource_user" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :resource_user

        expect(response.content_type).to eq("application/scim+json")
      end

      it "fails with no credentials" do
        get :resource_user

        expect(response.status).to eq(401)
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :resource_user

        expect(response.status).to eq(401)
      end
    end

    context "when authorized" do
      let(:body) { JSON.parse(response.body) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :resource_user

        expect(response.content_type).to eq("application/scim+json")
      end

      it "is successful with valid credentials" do
        get :resource_user

        expect(response.status).to eq(200)
      end

      it "successfully returns the configuration of the app" do
        get :resource_user

        expect(body.deep_symbolize_keys).to eq(ScimRails.config.resource_user_schema)
      end
    end
  end

  describe "resource_group" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :resource_group

        expect(response.content_type).to eq("application/scim+json")
      end

      it "fails with no credentials" do
        get :resource_group

        expect(response.status).to eq(401)
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :resource_group

        expect(response.status).to eq(401)
      end
    end

    context "when authorized" do
      let(:body) { JSON.parse(response.body) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :resource_group

        expect(response.content_type).to eq("application/scim+json")
      end

      it "is successful with valid credentials" do
        get :resource_group

        expect(response.status).to eq(200)
      end

      it "successfully returns the configuration of the app" do
        get :resource_group

        expect(body.deep_symbolize_keys).to eq(ScimRails.config.resource_group_schema)
      end
    end
  end
end
