require 'spec_helper'

module ScimRails
  RSpec.describe ScimSchemaController, type: :controller do
    include AuthHelper
    routes { ScimRails::Engine.routes }

    describe "get_schema" do
      let(:company) { create(:company) }
  
      context "when unauthorized" do
        it "returns scim+json content type" do
          get :get_schema, params: { id: 1 }
  
          expect(response.content_type).to eq("application/scim+json")
        end
  
        it "fails with no credentials" do
          get :get_schema, params: { id: 1 }
  
          expect(response.status).to eq(401)
        end
  
        it "fails with invalid credentials" do
          request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
  
          get :get_schema, params: { id: 1 }
  
          expect(response.status).to eq(401)
        end
      end
  
      context "when authorized" do
        let(:body) { JSON.parse(response.body) }
  
        before :each do
          http_login(company)
        end
  
        it "returns scim+json content type" do
          get :get_schema, params: { id: 1 }
  
          expect(response.content_type).to eq("application/scim+json")
        end
  
        it "is successful with valid credentials" do
          get :get_schema, params: { id: 1 }
  
          expect(response.status).to eq(200)
        end
  
        it "successfully returns the user schema" do
          get :get_schema, params: { id: "urn:ietf:params:scim:schemas:core:2.0:User" }
  
          expect(body.deep_symbolize_keys).to eq(ScimRails.config.retrievable_user_schema)
        end

        it "successfully returns the group schema" do
          get :get_schema, params: { id: "urn:ietf:params:scim:schemas:core:2.0:Group" }
  
          expect(body.deep_symbolize_keys).to eq(ScimRails.config.retrievable_group_schema)
        end
      end
    end
  end
end
