require "spec_helper"

RSpec.describe ScimRails::ScimUsersController, type: :controller do
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

    context "when when authorized" do
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
        create_list(:user, 10, company: company)

        get :index, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        expect(response_body["totalResults"]).to eq 10
      end

      it "defaults to 100 results" do
        create_list(:user, 300, company: company)

        get :index, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 300
        expect(response_body["Resources"].count).to eq 100
      end

      it "paginates results" do
        create_list(:user, 400, company: company)
        expect(company.users.first.id).to eq 1

        get :index, params: {
          startIndex: 101,
          count: 200,
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 200
        expect(response_body.dig("Resources", 0, "id")).to eq 101
      end

      it "paginates results by configurable scim_users_list_order" do
        allow(ScimRails.config).to receive(:scim_users_list_order).and_return({ created_at: :desc })

        create_list(:user, 400, company: company)
        expect(company.users.first.id).to eq 1

        get :index, params: {
          startIndex: 1,
          count: 10,
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 400
        expect(response_body["Resources"].count).to eq 10
        expect(response_body.dig("Resources", 0, "id")).to eq 400
      end

      it "filters results by provided email filter" do
        create(:user, email: "test1@example.com", company: company)
        create(:user, email: "test2@example.com", company: company)

        get :index, params: {
          filter: "email eq test1@example.com"
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 1
        expect(response_body["Resources"].count).to eq 1
      end

      it "filters results by provided name filter" do
        create(:user, first_name: "Chidi", last_name: "Anagonye", company: company)
        create(:user, first_name: "Eleanor", last_name: "Shellstrop", company: company)

        get :index, params: {
          filter: "familyName eq Shellstrop"
        }, as: :json
        response_body = JSON.parse(response.body)
        expect(response_body["totalResults"]).to eq 1
        expect(response_body["Resources"].count).to eq 1
      end

      it "returns no results for unfound filter parameters" do
        get :index, params: {
          filter: "familyName eq fake_not_there"
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
        create(:user, id: 1, company: company)
        get :show, params: { id: 1 }, as: :json

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        get :show, params: { id: "fake_id" }, as: :json

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1)

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
          name: {
            givenName: "New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }, as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        expect(company.users.count).to eq 0

        post :create, params: {
          name: {
            givenName: "New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }, as: :json

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
        user = company.users.first
        expect(user.persisted?).to eq true
        expect(user.first_name).to eq "New"
        expect(user.last_name).to eq "User"
        expect(user.email).to eq "new@example.com"
      end

      it "ignores unconfigured params" do
        post :create, params: {
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
        }, as: :json

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
      end

      it "returns 422 if required params are missing" do
        post :create, params: {
          name: {
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }, as: :json

        expect(response.status).to eq 422
        expect(company.users.count).to eq 0
      end

      it "returns 201 if user already exists and updates user" do
        create(:user, email: "new@example.com", company: company)

        post :create, params: {
          name: {
            givenName: "Not New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }, as: :json

        expect(response.status).to eq 201
        expect(company.users.count).to eq 1
        expect(company.users.first.first_name).to eq "Not New"
      end

      it "returns 409 if user already exists and config.scim_user_prevent_update_on_create is set to true" do
        allow(ScimRails.config).to receive(:scim_user_prevent_update_on_create).and_return(true)
        create(:user, email: "new@example.com", company: company)

        post :create, params: {
          name: {
            givenName: "Not New",
            familyName: "User"
          },
          emails: [
            {
              value: "new@example.com"
            }
          ]
        }, as: :json

        expect(response.status).to eq 409
        expect(company.users.count).to eq 1
      end

      it "creates and archives inactive user" do
        post :create, params: {
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
        }, as: :json

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
      let!(:user) { create(:user, id: 1, company: company) }

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

      it "deprovisions an active record" do
        request.content_type = "application/scim+json"
        put :put_update, params: put_params(active: false), as: :json

        expect(response.status).to eq 200
        expect(user.reload.active?).to eq false
      end

      it "reprovisions an inactive record" do
        user.archive!
        expect(user.reload.active?).to eq false
        request.content_type = "application/scim+json"
        put :put_update, params: put_params(active: true), as: :json

        expect(response.status).to eq 200
        expect(user.reload.active?).to eq true
      end

      it "returns :not_found for id that cannot be found" do
        get :put_update, params: { id: "fake_id" }, as: :json

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1000)

        get :put_update, params: { id: 1000 }, as: :json

        expect(response.status).to eq 404
      end

      it "is returns 422 with incomplete request" do
        put :put_update, params: {
          id: 1,
          userName: "test@example.com",
          emails: [
            {
              value: "test@example.com"
            },
          ],
          active: "true"
        }, as: :json

        expect(response.status).to eq 422
      end
    end
  end


  describe "patch update" do
    let(:company) { create(:company) }

    context "when unauthorized" do
      it "returns scim+json content type" do
        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "fails with no credentials" do
        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.status).to eq 401
      end

      it "fails with invalid credentials" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("unauthorized","123456")

        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.status).to eq 401
      end
    end

    context "when authorized" do
      let!(:user) { create(:user, id: 1, company: company) }

      before :each do
        http_login(company)
      end

      it "returns scim+json content type" do
        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.media_type).to eq "application/scim+json"
      end

      it "is successful with valid credentials" do
        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.status).to eq 200
      end

      it "returns :not_found for id that cannot be found" do
        get :patch_update, params: patch_params(id: "fake_id"), as: :json

        expect(response.status).to eq 404
      end

      it "returns :not_found for a correct id but unauthorized company" do
        new_company = create(:company)
        create(:user, company: new_company, id: 1000)

        get :patch_update, params: patch_params(id: 1000), as: :json

        expect(response.status).to eq 404
      end

      it "successfully archives user" do
        expect(company.users.count).to eq 1
        user = company.users.first
        expect(user.archived?).to eq false

        patch :patch_update, params: patch_params(id: 1), as: :json

        expect(response.status).to eq 200
        expect(company.users.count).to eq 1
        user.reload
        expect(user.archived?).to eq true
      end

      it "successfully restores user" do
        expect(company.users.count).to eq 1
        user = company.users.first.tap(&:archive!)
        expect(user.archived?).to eq true

        patch :patch_update, params: patch_params(id: 1,  active: true), as: :json

        expect(response.status).to eq 200
        expect(company.users.count).to eq 1
        user.reload
        expect(user.archived?).to eq false
      end

      it "is case insensetive for op value" do
        # Note, this is for backward compatibility. op should always
        # be lower case and support for case insensitivity will be removed
        patch :patch_update, params: {
          id: 1,
          Operations: [
            {
              op: "Replace",
              value: {
                active: false
              }
            }
          ]
        }, as: :json

        expect(response.status).to eq 200
      end

      it "throws an error for non status updates" do
        patch :patch_update, params: {
          id: 1,
          Operations: [
            {
              op: "replace",
              value: {
                name: {
                  givenName: "Francis"
                }
              }
            }
          ]
        }, as: :json

        expect(response.status).to eq 422
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
      end

      it "returns 422 when value is not an object" do
        patch :patch_update, params: {
          id: 1,
          Operations: [
            {
              op: "replace",
              path: "displayName",
              value: "Francis"
            }
          ]
        }

        expect(response.status).to eq 422
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
      end

      it "returns 422 when value is missing" do
        patch :patch_update, params: {
          id: 1,
          Operations: [
            {
              op: "replace"
            }
          ]
        }, as: :json

        expect(response.status).to eq 422
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
      end

      it "returns 422 operations key is missing" do
        patch :patch_update, params: {
          id: 1,
          Foobars: [
            {
              op: "replace"
            }
          ]
        }, as: :json

        expect(response.status).to eq 422
        response_body = JSON.parse(response.body)
        expect(response_body.dig("schemas", 0)).to eq "urn:ietf:params:scim:api:messages:2.0:Error"
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
