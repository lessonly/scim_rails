require "spec_helper"

RSpec.describe ScimRails::ScimUsersController, type: :request do
  include_context 'scim_authentication'

  let(:company) { create(:company) }

  let(:params) { {} }

  describe 'SCIM Authentication' do
    subject { response }

    context 'with valid authentication' do
      before { get '/scim_rails/scim/v2/Users', params: params, headers: valid_authentication_header }

      it { is_expected.to have_http_status :ok }
    end

    context 'without valid authentication' do
      before { get '/scim_rails/scim/v2/Users', params: params, headers: invalid_authentication_header }

      it { is_expected.to have_http_status :unauthorized }
    end
  end

  describe 'SCIM Users' do
    describe 'post' do
      let(:params) do
        {
          name: {
            givenName: "New",
            familyName: "User",
          },
          emails: [
            {
              value: "new@example.com",
            },
          ],
        }
      end

      it 'creates a new user' do
        post '/scim_rails/scim/v2/Users', params: params.to_json, headers: valid_authentication_header

        expect(request.params).to include :name
        expect(response.status).to eq 201
        expect(response.media_type).to eq "application/scim+json"
        expect(company.users.count).to eq 1
      end

      context 'when user already exists' do
        let(:first_name) { Faker::Name.first_name }
        let(:last_name) { Faker::Name.last_name }
        let(:email) { 'new@example.com' }
        let!(:user) { create(:user, first_name: first_name, last_name: last_name, company: company, email: email) }

        context 'when scim_user_prevent_update_on_create is true' do
          before do
            ScimRails.config.scim_user_prevent_update_on_create = true
          end

          it 'does not update the existing user' do
            post '/scim_rails/scim/v2/Users', params: params.to_json, headers: valid_authentication_header

            expect(response.status).to eq 409
            expect(company.users.count).to eq 1
            expect(company.users.first.first_name).to eq first_name
            expect(company.users.first.last_name).to eq last_name
          end
        end

        context 'when scim_user_prevent_update_on_create is false' do
          before do
            ScimRails.config.scim_user_prevent_update_on_create = false
          end

          it 'updates the existing user' do
            post '/scim_rails/scim/v2/Users', params: params.to_json, headers: valid_authentication_header

            expect(response.status).to eq 201
            expect(company.users.count).to eq 1
            expect(company.users.first.first_name).to eq 'New'
            expect(company.users.first.last_name).to eq 'User'
          end
        end
      end
    end

    describe 'patch' do
      let(:resp) { patch "/scim_rails/scim/v2/Users/#{target_person.id}", params: params.to_json, headers: valid_authentication_header }
      let!(:target_person) { create(:user, company: company) }

      context 'with azure request' do
        let(:params) do
          {
            id: target_person.id,
            Operations: [
              {
                "op": "replace",
                "path": "emails[type eq \"work\"].value",
                "value": "colten_grimes@boyle.us"
              },
              {
                "op": "replace",
                "value": {
                  "userName": "frederique.halvorson@dooley.co.uk",
                  "name.givenName": "Nico",
                  "name.familyName": "Grayson",
                  "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:department": "Sample Department"
                }
              }.compact,
            ],
          }
        end

        it "updates specific Person attribute" do
          expect(resp).to eq 200
          expect(target_person.reload.first_name).to eq('Nico')
          expect(target_person.reload.department).to eq('Sample Department')
        end
      end
    end
  end
end
