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
            get :index, params: {
              filter: "displayName eq #{search_term}"
            }
            
            expect(response_body["totalResults"]).to eq(1)
            expect(response_body["Resources"].count).to eq(1)
            expect(returned_resource["displayName"]).to eq(search_term)
          end

          it 'returns no results for unfound filter parameters' do
            get :index, params: {
              filter: "displayName eq #{unfound_search_term}"
            }

            expect(response_body["totalResults"]).to eq(0)
            expect(response_body["Resources"].count).to eq(0)
          end

          it 'raises an error for undefined filter queries' do
            get :index, params: {
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
          get :index, params: {
            startIndex: 10,
            count: 125
          }

          expect(response_body["totalResults"]).to eq(total_group_count)
          expect(response_body["Resources"].count).to eq(125)
          expect(response_body.dig("Resources", 0, "id")).to eq(10)
        end

        it "paginates results by configurable scim_groups_list_order" do
          allow(ScimRails.config).to receive(:scim_groups_list_order).and_return({ created_at: :desc })
  
          get :index, params: {
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
      before { get :show, params: { id: 1 } }

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

      let(:user_list_length) { 3 }
      let(:group_name) { Faker::Games::Pokemon.name }
      let(:invalid_id) { "invalid_id" }

      let!(:user_list) { create_list(:user, user_list_length) } 
      let!(:group) { create(:group, display_name: group_name, users: user_list, company: company) }

      let(:returned_resource) { JSON.parse(response.body) }

      it "returns scim+json content type" do
        get :show, params: { id: 1 }

        expect(response.content_type).to eq "application/scim+json"
      end

      it "returns :not_found for invalid id" do
        get :show, params: { id: invalid_id }
        
        expect(response.status).to eq(404)
      end

      context "with unauthorized group" do
        let(:unauthorized_id) { 2 }

        let!(:new_company) { create(:company) }
        let!(:unauthorized_group) { create(:group, company: new_company, id: unauthorized_id) }

        it "returns :not_found for correct id but unauthorized company" do
          get :show, params: { id: unauthorized_id }

          expect(response.status).to eq(404)
        end
      end

      it "is successful with correct id provided" do
        get :show, params: { id: 1 }

        expect(response.status).to eq(200)
        expect(returned_resource["displayName"]).to eq(group_name)
        expect(returned_resource["members"].map{ |res| res["value"] }).to match_array(Array(1..user_list_length))
      end
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

      let(:group_name) { Faker::Games::Pokemon.name }
      let(:group_email) { Faker::Internet.email }

      context "with valid credentials" do
        let(:modified_group_email) { Faker::Internet.email }

        let(:created_group) { company.groups.first }

        it "returns scim+json credentials" do
          post :create, params: {
            displayName: Faker::Games::Pokemon.name,
            email: Faker::Internet.email,
            members: []
          }
  
          expect(response.content_type).to eq "application/scim+json"
        end

        it "is successful" do
          expect(company.groups.count).to eq(0)
          expect(Group.count).to eq(0)

          post :create, params: {
            displayName: group_name,
            email: group_email,
            members: []
          }

          expect(response.status).to eq(201)

          expect(company.groups.count).to eq(1)
          expect(Group.count).to eq(1)

          expect(created_group.display_name).to eq(group_name)
          expect(created_group.email).to eq(group_email)
        end

        it "ignores unconfigured parameters" do
          post :create, params: {
            displayName: Faker::Games::Pokemon.name,
            email: Faker::Internet.email,
            members: [],
            unconfiguredParam: "unconfigured"
          }

          expect(response.status).to eq(201)
          expect(company.groups.count).to eq(1)
        end

        it 'updates group if existing display name used' do
          create(:group, display_name: group_name, company: company)

          post :create, params: {
            displayName: group_name,
            email: modified_group_email,
            members: []
          }

          expect(response.status).to eq(201)

          expect(company.groups.count).to eq(1)
          expect(created_group.email).to eq(modified_group_email)
        end

        it "creates and archives user" do
          post :create, params: {
            displayName: group_name,
            email: group_email,
            members: [],
            active: "false"
          }

          expect(response.status).to eq(201)
          expect(company.groups.count).to eq(1)

          expect(created_group.archived?).to eq(true)
        end
      end

      context "with invalid credentials" do
        it "returns 422 if required params missing" do
          post :create, params: {
            displayName: Faker::Name.name
          }

          expect(response.status).to eq(422)
          expect(company.groups.count).to eq(0)
        end

        it "returns 409 if display name taken and updating not allowed" do
          allow(ScimRails.config).to receive(:scim_group_prevent_update_on_create).and_return(true)
          create(:group, display_name: group_name, company: company)

          post :create, params: {
            displayName: group_name,
            email: group_email
          }

          expect(response.status).to eq(409)
          expect(company.groups.count).to eq(1)
        end
      end
    end
  end

  describe "put update" do
    context "when unauthorized" do
      before { put :put_update, params: { id: 1 } }

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

      let(:original_user_list_length) { 3 }
      let(:replacement_list_length) { 2 }

      let!(:user_list) { create_list(:user, original_user_list_length, company: company) }
      let!(:target_group) { create(:group, users: user_list, company: company) }

      let(:updated_group) { company.groups.first }
      let(:updated_user_list) { updated_group.users }

      context "with valid credentials" do
        let(:modified_name) { Faker::Games::Pokemon.name }
        let(:modified_email) { Faker::Internet.email }

        let!(:replacement_users) { create_list(:user, replacement_list_length, company: company) }
        let(:replacement_ids) { replacement_users.map{ |user| user[:id] }}

        it "returns scim+json content type" do
          put :put_update, params: put_params(id: target_group.id), as: :json

          expect(response.content_type).to eq("application/scim+json")
        end

        it "successfully updates a group" do
          put :put_update, params: put_params(id: target_group.id, displayName: modified_name, email: modified_email), as: :json

          expect(response.status).to eq(200)

          expect(updated_group.display_name).to eq(modified_name)
          expect(updated_group.email).to eq(modified_email)
        end

        it "reprovisions a group" do
          put :put_update, params: put_params(id: target_group, active: true), as: :json

          expect(response.status).to eq(200)

          expect(updated_group.active?).to eq(true)
        end

        it "deprovisions a group" do
          put :put_update, params: put_params(id: target_group, active: false), as: :json

          expect(response.status).to eq(200)

          expect(updated_group.active?).to eq(false)
        end

        it "replaces group's user list" do
          put :put_update, params: put_params(id: target_group.id, members: [ { value: replacement_ids[0] }, { value: replacement_ids[1] } ]), as: :json

          expect(response.status).to eq(200)

          expect(updated_user_list.length).to eq(replacement_list_length)
          expect(updated_user_list.map{ |user| user[:id] }).to match_array(replacement_ids)
        end

        it "does not add duplicates to groups" do
          put :put_update, params: put_params(id: target_group.id, members: [ { value: replacement_ids[0] }, { value: replacement_ids[1] }, { value: replacement_ids[1] } ]), as: :json

          expect(response.status).to eq(200)

          expect(updated_user_list.length).to eq(replacement_list_length)
        end

        it "clears a group's user list" do
          put :put_update, params: put_params(id: target_group.id), as: :json

          expect(response.status).to eq(200)

          expect(updated_user_list).to be_empty
        end

      end

      context "without valid credentials" do
        let(:invalid_group_id) { "invalid_group_id" }
        let(:invalid_user_id) { "invalid_user_id" }

        it "returns :not_found for id without a group" do
          put :put_update, params: put_params(id: invalid_group_id), as: :json

          expect(response.status).to eq(404)
        end

        it "returns 422 if attribute params missing" do
          put :put_update, params: {
            id: target_group.id,
            displayName: "Joe",
            members: []
          }, as: :json

          expect(response.status).to eq(422)

          expect(updated_user_list.length).to eq(original_user_list_length)
        end

        it "returns 400 if active param invalid" do
          put :put_update, params: put_params(id: target_group.id, active: "hotdog"), as: :json

          expect(response.status).to eq(400)

          expect(updated_user_list.length).to eq(original_user_list_length)
        end

        context "with invalid 'members' params" do
          let(:response_body) { JSON.parse(response.body) }

          it "returns :bad_request if missing" do
            put :put_update, params: {
              id: target_group.id
            }, as: :json

            expect(response.status).to eq(400)

            expect(updated_user_list.length).to eq(original_user_list_length)
          end

          it "returns :bad_request if not an array" do
            put :put_update, params: {
              id: target_group.id,
              members: Faker::Games::Pokemon.name
            }, as: :json

            expect(response.status).to eq(400)

            expect(updated_user_list.length).to eq(original_user_list_length)
          end

          it "returns :bad_request if not an array of hashes" do
            put :put_update, params: {
              id: target_group.id,
              members: [ Faker::Games::Pokemon.name, Faker::Games::Pokemon.location, Faker::Games::Pokemon.move ]
            }, as: :json

            expect(response.status).to eq(400)

            expect(updated_user_list.length).to eq(original_user_list_length)
          end

          it "returns :not_found for id without a user" do
            put :put_update, params: put_params(
              id: target_group.id,
              members: [
                {
                  value: invalid_user_id
                }
              ]
            ), as: :json
  
            expect(response.status).to eq(404)

            expect(updated_user_list.length).to eq(original_user_list_length)
          end
        end

      end
    end
  end

  describe "patch update" do
    context "when unauthorized" do
      before { patch :patch_update, params: { id: 1 } }

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

      let(:user_list_length) { 3 }

      let!(:user_list) { create_list(:user, user_list_length, company: company) }
      let!(:target_group) { create(:group, users: user_list, company: company) }

      context "with valid credentials" do
        let!(:new_user) { create(:user, company: company) }
        let(:new_user_id) { new_user.id }

        let(:updated_group) { company.groups.first }
        let(:updated_user_list) { updated_group.users }
        let(:updated_user_ids) { updated_user_list.map{ |user| user[:id] } }

        let(:new_display_name) { Faker::Name.first_name }
        let(:new_email) { Faker::Internet.email }

        it 'returns scim+json content type' do
          patch :patch_update, params: {
            id: target_group.id,
            Operations: []
          }, as: :json

          expect(response.content_type).to eq("application/scim+json")
        end

        context "when using 'replace' operation" do
          let(:replacement_list_length) { 2 }
          let!(:replacement_users) { create_list(:user, replacement_list_length, company: company) }
          let(:replacement_ids) { replacement_users.map{ |user| user[:id] } }

          it 'updates group attributes' do
            patch :patch_update, params: patch_replace_params(id: target_group.id, value: { displayName: new_display_name }), as: :json
  
            expect(response.status).to eq(200)
  
            expect(updated_group.display_name).to eq(new_display_name)
          end
  
          it 'reprovisions a group' do
            patch :patch_update, params: patch_replace_params(id: target_group.id, value: { active: true }), as: :json
  
            expect(response.status).to eq(200)
  
            expect(updated_group.active?).to eq(true)
          end
  
          it 'deprovisions a group' do
            patch :patch_update, params: patch_replace_params(id: target_group.id, value: { active: false }), as: :json
  
            expect(response.status).to eq(200)
  
            expect(updated_group.active?).to eq(false)
          end

          it "replaces a group's user list with another" do
            patch :patch_update, params: patch_replace_params(id: target_group.id, path: "members", value: [ { value: replacement_ids[0] }, { value: replacement_ids[1] } ]), as: :json

            expect(response.status).to eq(200)

            expect(updated_user_list.length).to eq(replacement_list_length)
            expect(updated_user_ids).to match_array(replacement_ids)
          end

          it "replaces a group's user list to be empty" do
            patch :patch_update, params: patch_replace_params(id: target_group.id, path: "members", value: []), as: :json

            expect(response.status).to eq(200)

            expect(updated_user_list).to be_empty
          end
        end

        context "when using 'add' operation" do
          it 'adds user to group' do
            patch :patch_update, params: patch_add_params(id: target_group.id, value: [ { value: new_user_id } ]), as: :json

            expect(response.status).to eq(200)

            expect(updated_user_list.length).to eq(user_list_length + 1)
            expect(updated_user_ids).to include(new_user_id)
          end

          it 'will not add same user to group more than once' do
            patch :patch_update, params: patch_add_params(id: target_group.id, value: [ { value: new_user_id }, { value: new_user_id } ]), as: :json

            expect(updated_user_list.length).to eq(user_list_length + 1)
          end
        end

        context "when using 'remove' operation" do
          let(:target_user_id) { user_list.first.id }

          it 'removes target users from group' do
            patch :patch_update, params: patch_remove_params(id: target_group.id, path: "members[value eq \"#{target_user_id}\"]"), as: :json

            expect(response.status).to eq(200)
            
            expect(updated_user_list.length).to eq(user_list_length - 1)
          end

          it 'does not remove if values not found' do
            patch :patch_update, params: patch_remove_params(id: target_group.id, path: "members[value eq \"unknown\"]"), as: :json

            expect(response.status).to eq(200)

            expect(updated_user_list.length).to eq(user_list_length)
          end

          it 'removes all users if no member filter' do
            patch :patch_update, params: patch_remove_params(id: target_group.id, path: "members"), as: :json

            expect(response.status).to eq(200)

            expect(updated_user_list).to be_empty
          end
        end

        it "works with more than one operation" do
          patch :patch_update, params: {
            id: target_group.id,
            Operations: [
              {
                op: "replace",
                value: {
                  email: new_email,
                  displayName: new_display_name
                }
              },
              {
                op: "remove",
                path: "members"
              },
              {
                op: "add",
                value: [
                  {
                    value: new_user_id
                  }
                ]
              }
            ]
          }, as: :json

          expect(response.status).to eq(200)

          expect(updated_group.display_name).to eq(new_display_name)
          expect(updated_group.email).to eq(new_email)

          expect(updated_user_list.length).to eq(1)
          expect(updated_user_ids).to include(new_user_id)
        end
      end

      context "without valid credentials" do
        let(:invalid_id) { "invalid_id" }

        it "returns 404 if for id not belonging to group" do
          patch :patch_update, params: {
            id: invalid_id,
            Operations: []
          }, as: :json

          expect(response.status).to eq(404)
        end

        it 'returns 404 when adding nonexistent user' do
          patch :patch_update, params: patch_add_params(id: target_group, value: [ { value: "N/A" } ]), as: :json

          expect(response.status).to eq(404)
        end

        it "returns 400 for invalid active param" do
          patch :patch_update, params: patch_replace_params(id: target_group.id, value: { active: "hotdog" }), as: :json

          expect(response.status).to eq(400)
        end

        context "with unprocessable paths" do
          it "returns 422 for 'replace'" do
            patch :patch_update, params: patch_replace_params(id: target_group.id, path: "unprocessable_path"), as: :json

            expect(response.status).to eq(422)
          end

          it "returns 422 for 'remove'" do
            patch :patch_update, params: patch_remove_params(id: target_group.id, path: "unprocessable_path"), as: :json

            expect(response.status).to eq(422)
          end

          it "returns 422 for bad filter" do
            patch :patch_update, params: patch_remove_params(id: target_group.id, path: "members[value eq]"), as: :json

            expect(response.status).to eq(422)
          end
        end
      end

    end

    describe "delete" do
      let(:company) { create(:company) }
  
      context "when unauthorized" do
        before { delete :delete, params: { id: 1 } }
  
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
  
        let(:group_id) { 1 }
        let(:invalid_id) { "invalid_id" }
        
        let!(:user_list) { create_list(:user, 3, company: company) }
  
        let!(:group) { create(:group, users: user_list, company: company) }
  
        it "returns :not_found for invalid id" do
          delete :delete, params: { id: invalid_id }
  
          expect(response.status).to eq(404)
        end
  
        context "with unauthorized group" do
          let(:unauthorized_id) { 2 }
  
          let!(:new_company) { create(:company) }
          let!(:unauthorized_group) { create(:group, company: new_company, id: unauthorized_id) }
  
          it "returns :not_found for correct id but unauthorized company" do
            delete :delete, params: { id: unauthorized_id }
  
            expect(response.status).to eq(404)
          end
        end
  
        it "successfully deletes for correct id provided" do
          delete :delete, params: { id: group_id }
  
          expect(response.status).to eq(204)
          expect(Group.count).to eq(0)
        end
      end
    end
  end

  def put_params(id:, displayName: Faker::Name.name, email: Faker::Internet.email, members: [], active: true)
    {
      id: id,
      displayName: displayName,
      email: email,
      members: members,
      active: active
    }
  end

  def patch_remove_params(id:, path:)
    {
      id: id,
      Operations: [
        {
          op: "remove",
          path: path
        }
      ]
    }
  end

  def patch_add_params(id:, value:)
    {
      id: id,
      Operations: [
        {
          op: "add",
          value: value
        }
      ]
    }
  end

  def patch_replace_params(id:, path: nil, value: nil)
    {
      id: id,
      Operations: [
        {
          op: "replace",
          path: path,
          value: value
        }
      ]
    }.compact
  end
end
