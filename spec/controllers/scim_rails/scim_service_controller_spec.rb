require "spec_helper"

RSpec.describe ScimRails::ScimServiceController, type: :controller do
  include AuthHelper

  routes { ScimRails::Engine.routes }

  describe "configuration" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :configuration

        expect(response.content_type).to eq("application/scim+json")
      end

      it "fails with no credentials" do
        get :configuration

        expect(response.status).to eq(401)
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :configuration

        expect(response.status).to eq(401)
      end
    end

    context "when authorized" do
      let(:body) { JSON.parse(response.body) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :configuration

        expect(response.content_type).to eq("application/scim+json")
      end

      it "is successful with valid credentials" do
        get :configuration

        expect(response.status).to eq(200)
      end

      it "successfully returns the configuration of the app" do
        get :configuration

        expect(body.deep_symbolize_keys).to eq(ScimRails.config.config_schema)
      end

      context "when before_scim_response is defined" do
        before do
          ScimRails.config.before_scim_response = lambda do |body|
            print "#{body}"
          end
        end

        after do
          ScimRails.config.before_scim_response = nil
        end

        it "successfully calls before_scim_response" do
          get :configuration

          expect{ get :configuration }.to output("#{request.params}").to_stdout
        end
      end

      context "when after_scim_response is defined" do
        before do
          ScimRails.config.after_scim_response = lambda do |object, status|
            print "#{object} #{status}"
          end
        end

        after do
          ScimRails.config.after_scim_response = nil
        end

        it "successfully calls after_scim_response" do
          expect{ get :configuration }.to output("#{ScimRails.config.config_schema} RETRIEVED").to_stdout
        end
      end
    end
  end
end
