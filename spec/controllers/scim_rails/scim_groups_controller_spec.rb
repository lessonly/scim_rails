require "spec_helper"

RSpec.describe ScimRails::ScimGroupsController, type: :controller do
  include AuthHelper

  routes { ScimRails::Engine.routes }

  describe "index" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :index, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        get :index, as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :index, as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :index, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        get :index, as: :json

        expect(response.status).to eq 200
      end

      it "returns all results" do
        create_list(:group, 5, company: company)

        get :index, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        expect(response_body["totalResults"]).to eq 5
      end

      it "defaults to 100 results" do
        create_list(:group, 300, company: company)

        get :index, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 300
        expect(response_body["Resources"].count).to eq 100
      end

      it "paginates results" do
        create_list(:group, 400, company: company)
        expect(company.groups.first.id).to eq 1

        get :index, params: {
          startIndex: 101,
          count: 200,
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 200
        expect(response_body.dig("Resources", 0, "id")).to eq 101
      end

      it "paginates results by configurable scim_groups_list_order" do
        allow(ScimRails.config).to receive(:scim_groups_list_order).and_return({ created_at: :desc })

        create_list(:group, 400, company: company)
        expect(company.groups.first.id).to eq 1

        get :index, params: {
          startIndex: 1,
          count: 10,
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 10
        expect(response_body.dig("Resources", 0, "id")).to eq 400
      end

      it "filters results by provided displayName filter" do
        create(:group, name: "Foo", company: company)
        create(:group, name: "Bar", company: company)

        get :index, params: {
          filter: "displayName eq Bar"
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 1
        expect(response_body["Resources"].count).to eq 1
        expect(response_body.dig("Resources", 0, "displayName")).to eq "Bar"
      end

      it "returns no results for unfound filter parameters" do
        get :index, params: {
          filter: "displayName eq fake_not_there"
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 0
        expect(response_body["Resources"].count).to eq 0
      end

      it "returns no results for undefined filter queries" do
        get :index, params: {
          filter: "address eq 101 Nowhere USA"
        }, as: :json
        expect(response.status).to eq 400
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
      end
    end
  end

  describe "show" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :show, params: { id: 1 }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        get :show, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :show, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :show, params: { id: 1 }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        create(:group, id: 1, company: company)
        get :show, params: { id: 1 }, as: :json

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        get :show, params: { id: "fake_id" }, as: :json

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:group, company: new_company, id: 1)

        get :show, params: { id: 1 }, as: :json

        expect(response.status).to eq 404
      end
    end
  end

  describe "create" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        post :create, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        post :create, as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        post :create, as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        post :create, params: {
          displayName: "Test Group",
          members: []
        }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        expect(company.groups.count).to eq 0

        post :create, params: {
          displayName: "Test Group",
          members: []
        }, as: :json

        expect(response.status).to eq 201
        expect(company.groups.count).to eq 1
        group = company.groups.first
        expect(group.persisted?).to eq true
        expect(group.name).to eq "Test Group"
        expect(group.users).to eq []
      end

      it "ignores unconfigured params" do
        post :create, params: {
          displayName: "Test Group",
          department: "Best Department",
          members: []
        }, as: :json

        expect(response.status).to eq 201
        expect(company.groups.count).to eq 1
      end

      it "returns 422 if required params are missing" do
        post :create, params: {
          members: []
        }, as: :json

        expect(response.status).to eq 422
        expect(company.users.count).to eq 0
      end

      it "returns 409 if group already exists" do
        create(:group, name: "Test Group", company: company)

        post :create, params: {
          displayName: "Test Group",
          members: []
        }, as: :json

        expect(response.status).to eq 409
        expect(company.groups.count).to eq 1
      end

      it "creates group" do
        users = create_list(:user, 3, company: company)

        post :create, params: {
          displayName: "Test Group",
          members: users.map do |user|
            { value: user.id.to_s, display: user.email }
          end
        }, as: :json

        expect(response.status).to eq 201
        expect(company.groups.count).to eq 1
        group = company.groups.first
        expect(group.name).to eq "Test Group"
        expect(group.users.count).to eq 3
      end
    end
  end

  describe "put update" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        put :put_update, params: { id: 1 }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        put :put_update, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        put :put_update, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      let!(:group) { create(:group, id: 1, company: company) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        put :put_update, params: put_params, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with with valid credentials" do
        put :put_update, params: put_params, as: :json

        expect(response.status).to eq 200
      end

      it "can add and delete Users from a Group at once" do
        user1 = create(:user, company: company, groups: [group])
        user2 = create(:user, company: company)

        expect do
          put :put_update, params: put_params(users: [user2]), as: :json
        end.to change { group.reload.users }.from([user1]).to([user2])

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        put :put_update, params: { id: "fake_id" }, as: :json

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:group, company: new_company, id: 1000)

        put :put_update, params: { id: 1000 }, as: :json

        expect(response.status).to eq 404
      end

      it "returns 422 with incomplete request" do
        put :put_update, params: {
          id: 1,
          members: []
        }, as: :json

        expect(response.status).to eq 422
      end
    end
  end

  describe "destroy" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        delete :destroy, params: { id: 1 }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        delete :destroy, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        delete :destroy, params: { id: 1 }, as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      let!(:group) { create(:group, id: 1, company: company) }

      before :each do
        http_login(company)
      end

      context "when Group destroy method is configured" do
        before do
          allow(ScimRails.config).to receive(:group_destroy_method).and_return(:destroy!)
        end

        it "returns empty response" do
          delete :destroy, params: { id: 1 }, as: :json

          expect(response.body).to be_empty
        end

        it "is successful with valid credentials" do
          delete :destroy, params: { id: 1 }, as: :json

          expect(response.status).to eq 204
        end

        it "returns :not_found for id that cannot be found" do
          delete :destroy, params: { id: "fake_id" }, as: :json

          expect(response.status).to eq 404
        end

        it "returns :not_found for a correct id but unauthorized company" do
          new_company = create(:company)
          create(:group, company: new_company, id: 1000)

          delete :destroy, params: { id: 1000 }, as: :json

          expect(response.status).to eq 404
        end

        it "successfully deletes Group" do
          expect do
            delete :destroy, params: { id: 1 }, as: :json
          end.to change { company.groups.reload.count }.from(1).to(0)

          expect(response.status).to eq 204
        end
      end

      context "when Group destroy method is not configured" do
        it "does not delete Group" do
          allow(ScimRails.config).to receive(:group_destroy_method).and_return(nil)

          expect do
            delete :destroy, params: { id: 1 }, as: :json
          end.not_to change { company.groups.reload.count }.from(1)

          expect(response.status).to eq 501
        end
      end
    end
  end

  def put_params(name: "Test Group", users: [])
    {
      id: 1,
      displayName: name,
      members: users.map { |user| { value: user.id.to_s, display: user.email } }
    }
  end
end
