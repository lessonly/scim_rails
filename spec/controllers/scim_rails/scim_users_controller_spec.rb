require "spec_helper"

RSpec.describe ScimRails::ScimUsersController, type: :controller do
  include AuthHelper

  routes { ScimRails::Engine.routes }

  describe "index" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        get :index

        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        get :index

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :index

        expect(response.status).to eq 401
      end
    end

    context "when when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :index

        expect(response.content_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        get :index

        expect(response.status).to eq 200
      end

      it "returns all results" do
        create_list(:user, 10, company: company)

        get :index
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        expect(response_body["totalResults"]).to eq 10
      end

      it "defaults to 100 results" do
        create_list(:user, 300, company: company)

        get :index
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 300
        expect(response_body["Resources"].count).to eq 100
      end

      it "paginates results" do
        create_list(:user, 400, company: company)
        expect(company.users.first.id).to eq 1

        get :index, {
          startIndex: 101,
          count: 200,
        }
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 200
        expect(response_body.dig("Resources", 0, "id")).to eq 101
      end

      it "paginates results by configurable scim_users_list_order" do
        allow(ScimRails.config).to receive(:scim_users_list_order).and_return({ created_at: :desc })

        create_list(:user, 400, company: company)
        expect(company.users.first.id).to eq 1

        get :index, {
          startIndex: 1,
          count: 10,
        }
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 10
        expect(response_body.dig("Resources", 0, "id")).to eq 400
      end

      it "filters results by provided email filter" do
        create(:user, email: "test1@example.com", company: company)
        create(:user, email: "test2@example.com", company: company)

        get :index, {
          filter: "email eq test1@example.com"
        }
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 1
        expect(response_body["Resources"].count).to eq 1
      end

      it "filters results by provided name filter" do
        create(:user, first_name: "Chidi", last_name: "Anagonye", company: company)
        create(:user, first_name: "Eleanor", last_name: "Shellstrop", company: company)

        get :index, {
          filter: "familyName eq Shellstrop"
        }
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 1
        expect(response_body["Resources"].count).to eq 1
      end

      it "returns no results for unfound filter parameters" do
        get :index, {
          filter: "familyName eq fake_not_there"
        }
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 0
        expect(response_body["Resources"].count).to eq 0
      end

      it "returns no results for undefined filter queries" do
        get :index, {
          filter: "address eq 101 Nowhere USA"
        }
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
        get :show, { id: 1 }

        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        get :show, { id: 1 }

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        get :show, { id: 1 }

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        get :show, { id: 1 }

        expect(response.content_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        create(:user, id: 1, company: company)
        get :show, { id: 1 }

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        get :show, { id: "fake_id" }

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1)

        get :show, { id: 1 }

        expect(response.status).to eq 404
      end
    end
  end


  describe "create" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        post :create

        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        post :create

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        post :create

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        post :create, {
          name: {
            givenName: "New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.content_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        expect(company.users.count).to eq 0

        post :create, {
          name: {
            givenName: "New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
        user = company.users.first
        expect(user.persisted?).to eq true
        expect(user.first_name).to eq "New"
        expect(user.last_name).to eq "User"
        expect(user.email).to eq "new@example.com"
        expect(user.random_attribute).to eq true
      end

      it "ignores unconfigured params" do
        post :create, {
          name: {
            formattedName: "New User",
            givenName: "New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
      end

      it "returns 422 if required params are missing" do
        post :create, {
          name: {
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.status).to eq 422
        expect(company.users.count).to eq 0
      end

      it "returns 201 if user already exists and updates user" do
        create(:user, email: "new@example.com", company: company)

        post :create, {
          name: {
            givenName: "Not New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
        expect(company.users.first.first_name).to eq "Not New"
      end

      it "returns 409 if user already exists and config.scim_user_prevent_update_on_create is set to true" do
        allow(ScimRails.config).to receive(:scim_user_prevent_update_on_create).and_return(true)
        create(:user, email: "new@example.com", company: company)

        post :create, {
          name: {
            givenName: "Not New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }

        expect(response.status).to eq 409
        expect(company.users.count).to eq 1
      end

      it "creates and archives inactive user" do
        post :create, {
          id: 1,
          userName: "test@example.com",
          name: {
            givenName: "Test",
            familyName: "User"
          },
          emails: [
            {
              value: "test@example.com"
            },
          ],
          active: "false"
        }

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
        user = company.users.first
        expect(user.archived?).to eq true
      end
    end
  end


  describe "put update" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        put :put_update, { id: 1 }

        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        put :put_update, { id: 1 }

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        put :put_update, { id: 1 }

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      let!(:user) { create(:user, id: 1, company: company) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        put :put_update, put_params

        expect(response.content_type).to eq "application/scim+json"
      end

      it "is successful with with valid credentials" do
        put :put_update, put_params

        expect(response.status).to eq 200
      end

      it "deprovisions an active record" do
        request.format = "application/scim+json"
        put :put_update, put_params(active: false)

        expect(response.status).to eq 200
        expect(user.reload.active?).to eq false
      end

      it "reprovisions an inactive record" do
        user.archive!
        expect(user.reload.active?).to eq false
        request.format = "application/scim+json"
        put :put_update, put_params(active: true)

        expect(response.status).to eq 200
        expect(user.reload.active?).to eq true
      end

      it "returns :not_found for id that cannot be found" do
        get :put_update, { id: "fake_id" }

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1000)

        get :put_update, { id: 1000 }

        expect(response.status).to eq 404
      end

      it "is returns 422 with incomplete request" do
        put :put_update, {
          id: 1,
          userName: "test@example.com",
          emails: [
            {
              value: "test@example.com"
            },
          ],
          active: "true"
        }

        expect(response.status).to eq 422
      end
    end
  end


  describe "patch update" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        patch :patch_update, patch_params(id: 1)

        expect(response.content_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        patch :patch_update, patch_params(id: 1)

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        patch :patch_update, patch_params(id: 1)

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      let!(:user) { create(:user, id: 1, company: company) }
      let(:company_user) { company.users.first }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        patch :patch_update, patch_params(id: 1)

        expect(response.content_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        patch :patch_update, patch_params(id: 1)

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        get :patch_update, patch_params(id: "fake_id")

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1000)

        get :patch_update, patch_params(id: 1000)

        expect(response.status).to eq 404
      end

      it "returns 422 error for an op that isn't 'replace'" do
        patch :patch_update, {
          id: 1,
          Operations: [
            {
              op: "remove"
            }
          ]
        }

        expect(response.status).to eq(422)

        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
        expect(response_body["detail"]).to eq("Invalid PATCH request. This PATCH endpoint only 'replace' operations.")
      end

      it "successfully archives user" do
        expect(company.users.count).to eq 1
        user = company.users.first
        expect(user.archived?).to eq false

        patch :patch_update, patch_params(id: 1)

        expect(response.status).to eq 200
        expect(company.users.count).to eq 1
        user.reload
        expect(user.archived?).to eq true
      end

      it "successfully restores user" do
        expect(company.users.count).to eq 1
        user = company.users.first.tap(&:archive!)
        expect(user.archived?).to eq true

        patch :patch_update, patch_params(id: 1,  active: true)

        expect(response.status).to eq 200
        expect(company.users.count).to eq 1
        user.reload
        expect(user.archived?).to eq false
      end

      context 'when changing non-status attributes' do
        let(:new_given_name) { Faker::Name.first_name }
        let(:new_family_name) { Faker::Name.last_name }

        let(:new_email) { Faker::Internet.email }

        let(:final_given_name) { Faker::Name.first_name }
        let(:final_family_name) { Faker::Name.last_name }

        it 'changes only name' do
          patch :patch_update, {
            id: 1,
            Operations: [
              {
                op: "replace",
                value: {
                  name: {
                    givenName: new_given_name,
                    familyName: new_family_name
                  }
                }
              }
            ]
          }

          expect(response.status).to eq(200)
          expect(company_user.first_name).to eq(new_given_name)
          expect(company_user.last_name).to eq(new_family_name)
        end

        it 'changes email' do
           patch :patch_update, {
              id: 1,
              Operations: [
                {
                  op: "replace",
                  value: {
                    emails: [
                      {
                        value: new_email
                      }
                    ]
                  }
                }
              ]
           }

           expect(response.status).to eq(200)
           expect(company_user.email).to eq(new_email)
        end

        it 'works with more than one Operation' do
          patch :patch_update, {
            id: 1,
            Operations: [
              {
                op: "replace",
                value: {
                  name: {
                    givenName: new_given_name,
                    familyName: new_family_name
                  }
                }
              },
              {
                op: "replace",
                value: {
                  name: {
                    givenName: final_given_name,
                    familyName: final_family_name
                  }
                }
              }
            ]
          }

          expect(response.status).to eq(200)
          expect(company_user.first_name).to eq(final_given_name)
          expect(company_user.last_name).to eq(final_family_name)
        end
      end
    end
  end


  describe "delete" do
    let(:company) { create(:company) }
  
    context "when unauthorized" do
      before { delete :delete, { id: 1 } }

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

    context 'when authorized' do
      let(:user_id) { 1 }
      let(:invalid_id) { "invalid_id" }

      let!(:user) { create(:user, id: user_id, company: company) }

      before :each do
        http_login(company)
      end

      it "returns :not_found for invalid id" do
        delete :delete, { id: invalid_id }

        expect(response.status).to eq(404)
      end

      context "with unauthorized user" do
        let(:unauthorized_id) { 2 }

        let!(:new_company) { create(:company) }
        let!(:unauthorized_user) { create(:user, company: new_company, id: unauthorized_id) }

        it "returns :not_found for correct id but unauthorized company" do
          delete :delete, { id: unauthorized_id }
          
          expect(response.status).to eq(404)
        end
      end

      it "successfully deletes for correct id provided" do
        delete :delete, { id: user_id }

        expect(response.status).to eq(204)
        expect(User.count).to eq(0)
      end
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

  def put_params(active: true)
    {
      id: 1,
      userName: "test@example.com",
      name: {
        givenName: "Test",
        familyName: "User"
      },
      emails: [
        {
          value: "test@example.com"
        },
      ],
      active: active
    }
  end
end
