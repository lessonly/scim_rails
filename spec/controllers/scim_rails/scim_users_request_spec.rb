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
                  "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization": "Sample Company",
                  "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:department": "Sample Department"
                }
              }.compact,
            ],
          }
        end

        it "updates specific Person attribute" do
          expect(resp).to eq 200
          expect(target_person.reload.first_name).to eq('Nico')
          expect(subject.company).to eq('Sample Company')
          expect(subject.department).to eq('Sample Department')
        end
      end
    end
  end
end
