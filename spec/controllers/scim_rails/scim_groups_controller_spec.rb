require 'spec_helper'

RSpec.describe ScimRails::ScimGroupsController, type: :controller do
  include AuthHelper

  routes { ScimRails::Engine.routes }
  let(:company) { create(:company) }

  describe 'index' do
    context 'without authorization' do
      before { get :index }

      it "returns scim+json content type" do
        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
        expect(response.status).to eq 401
      end
    end

    context 'with authorization' do
      before :each do
        http_login(company)
      end

      let(:user_list_length) { 3 }
      let(:user_list) { create_list(:user, user_list_length, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, company: company) }
      let(:response_body) { JSON.parse(response.body) }

      it 'returns scim+json content type' do
        get :index
        expect(response.content_type).to eq "application/scim+json"
      end

      it 'is successful' do
        get :index
        expect(response.status).to eq(200)
      end

      context 'when less than 100 existing groups' do
        let(:total_group_count) { 10 }

        let(:returned_resource) { response_body["Resources"].first }
        let!(:group_list) { create_list(:group, total_group_count, users: user_list, company: company) }

        it 'returns all results' do
          get :index
          expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:ListResponse"
          expect(response_body["totalResults"]).to eq(total_group_count)
        end

        it 'returns the correct data for members' do
          get :index
          expect(returned_resource["members"].map{ |res| res["value"] }).to match_array(Array(1..user_list_length))
        end

        context 'with filter parameters' do
          let(:search_term) { Faker::Games::Pokemon.name }
          let(:not_search_term) { search_term[0, search_term.length - 1] }
          let(:unfound_search_term) { search_term[0, search_term.length - 2] }

          let!(:group_with_search_term) { create(:group, display_name: search_term, company: company) }
          let!(:group_without_search_term) { create(:group, display_name: not_search_term, company: company) }

          it 'filters results by provided display name' do
            get :index, {
              filter: "displayName eq #{search_term}"
            }
            
            expect(response_body["totalResults"]).to eq(1)
            expect(response_body["Resources"].count).to eq(1)
            expect(returned_resource["displayName"]).to eq(search_term)
          end

          it 'returns no results for unfound filter parameters' do
            get :index, {
              filter: "displayName eq #{unfound_search_term}"
            }

            expect(response_body["totalResults"]).to eq(0)
            expect(response_body["Resources"].count).to eq(0)
          end

          it 'raises an error for undefined filter queries' do
            get :index, {
              filter: "nameDisplay eq will_raise_error"
            }

            expect(response.status).to eq(400)
            expect(response_body.dig("schemas", 0)).to eq("urn:ietf:params:scim:api:messages:2.0:Error")
          end
        end
      end

      context 'when more than 100 existing groups' do
        let(:total_group_count) { 150 }
        let!(:all_groups) { create_list(:group, total_group_count, users: [], company: company) }

        it 'returns a max of 100 results' do
          get :index
          expect(response_body["totalResults"]).to eq(total_group_count)
          expect(response_body["Resources"].count).to eq(100)
        end

        it 'paginates results' do
          get :index, {
            startIndex: 10,
            count: 125
          }

          expect(response_body["totalResults"]).to eq(total_group_count)
          expect(response_body["Resources"].count).to eq(125)
          expect(response_body.dig("Resources", 0, "id")).to eq(10)
        end

        it "paginates results by configurable scim_groups_list_order" do
          allow(ScimRails.config).to receive(:scim_groups_list_order).and_return({ created_at: :desc })
  
          get :index, {
            startIndex: 1,
            count: 10,
          }

          expect(response_body["totalResults"]).to eq(total_group_count)
          expect(response_body["Resources"].count).to eq(10)
          expect(response_body.dig("Resources", 0, "id")).to eq(total_group_count)
        end
      end
    end
  end

  describe 'show' do
    context "when unauthorized" do
      before { get :show, { id: 1 } }

      it "returns scim+json content type" do
        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      # TODO: add tests once method is implemented
    end
  end

  describe "create" do
    context "when unauthorized" do
      before { post :create }

      it "returns scim+json content type" do
        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      # TODO: add tests once method is implemented
    end
  end

  describe "put update" do
    context "when unauthorized" do
      before { put :put_update, { id: 1 } }

      it "returns scim+json content type" do
        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      # TODO: add tests once method is implemented
    end
  end

  describe "patch update" do
    context "when unauthorized" do
      before { patch :patch_update, patch_params(id: 1) }

      it "returns scim+json content type" do
        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")
        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      # TODO: add tests once method is implemented
    end
  end

  def patch_params(id:, active: false)
    {
      id: id,
      Operations: [
        {
          op: "replace",
          value: {
            active: active
          }
        }
      ]
    }
  end
end
