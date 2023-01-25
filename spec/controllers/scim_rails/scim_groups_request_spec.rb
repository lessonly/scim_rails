require 'spec_helper'

RSpec.describe ScimRails::ScimGroupsController, type: :request do
  include_context 'scim_authentication'

  let(:company) { create(:company) }

  let(:params) { {} }

  describe 'SCIM Authentication' do
    subject { response }

    context 'with valid authentication' do
      before { get '/scim_rails/scim/v2/Groups', params: params, headers: valid_authentication_header }

      it { is_expected.to have_http_status :ok }
    end

    context 'without valid authentication' do
      before { get '/scim_rails/scim/v2/Groups', params: params, headers: invalid_authentication_header }

      it { is_expected.to have_http_status :unauthorized }
    end
  end

  describe 'SCIM Groups' do
    describe 'index' do
      let(:group_list_length) { 10 }
      let!(:group_list) { create_list(:group, group_list_length, company: company) }

      context 'with valid request' do
        before { get '/scim_rails/scim/v2/Groups', params: params.to_json, headers: valid_authentication_header }

        it 'returns a PersonGroup list' do
          expect(last_response_as_hash[:Resources].count).to eq(group_list_length)
        end
      end

      context 'with Azure request' do
        let!(:new_group) { create(:group, company: company, display_name: 'TEST GROUP') }

        context 'when filter is present and same case' do
          before { get '/scim_rails/scim/v2/Groups?filter=displayName+eq+"TEST GROUP"', params: params.to_json, headers: valid_authentication_header }

          it 'returns a Group list' do
            expect(last_response_as_hash[:Resources].count).to eq(1)
            expect(last_response_as_hash[:Resources][0][:id]).to eq(new_group.id)
          end
        end

        context 'when filter is present and not the same casing' do
          before { get '/scim_rails/scim/v2/Groups?filter=displayName+eq+"test group"', params: params.to_json, headers: valid_authentication_header }

          it 'returns a Group list' do
            expect(last_response_as_hash[:Resources].count).to eq(1)
            expect(last_response_as_hash[:Resources][0][:id]).to eq(new_group.id)
          end
        end
      end
    end

    describe 'show' do
      let(:user_list_length) { 3 }
      let!(:user_list) { create_list(:user, user_list_length, company: company) }
      let(:user_list_ids) { user_list.map { |user| user[:id] } }
      let!(:target_group) { create(:group, company: company, users: user_list) }

      let(:params) { { id: target_group.id } }

      context 'with valid request' do
        before { get "/scim_rails/scim/v2/Groups/#{target_group.id}", params: params.to_json, headers: valid_authentication_header }

        it 'returns a specific PersonGroup' do
          expect(last_response_as_hash[:id]).to eq(target_group.id)
          expect(last_response_as_hash[:members].map { |member| member[:value] }).to match_array(user_list_ids)
        end
      end

      context "with Azure requests" do
        before { get "/scim_rails/scim/v2/Groups/#{target_group.id}?excludedAttributes=members", params: params.to_json, headers: valid_authentication_header }

        it 'returns a specific Group' do
          expect(last_response_as_hash[:id]).to eq(target_group.id)
          expect(last_response_as_hash[:members]).to be_nil
        end
      end
    end
  end
end