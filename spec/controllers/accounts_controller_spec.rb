# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::AccountsController do
  let!(:bank) { create(:bank) }
  let!(:account_1) { create(:account, bank: bank) }
  let!(:account_2) { create(:account, bank: bank) }

  describe 'GET #index' do
    before { get :index }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'JSON body response contains expected accounts' do
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(Account.all.count)
    end
  end

  describe 'GET #show' do
    it 'should test show action to be success' do
      get :show, params: { id: account_1.id }
      expect(response).to have_http_status(:success)
    end

    it 'should render account' do
      get :show, params: { id: account_1.id }
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(account_1.id)
    end

    it 'should render not render account_1' do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'POST #create' do
    let(:valid_params) do
      { bank_id: bank.id, name: 'Test Account' }
    end

    let(:invalid_params) do
      { bank_id: bank.id, name: '' }
    end

    it 'should create account' do
      expect {
        post :create, params: { account: valid_params }, as: :json
      }.to change(Account, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it 'should not create account when validation fails' do
      expect {
        post :create, params: { account: invalid_params }, as: :json
      }.to change(Account, :count).by(0)
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'PUT #update' do
    it 'should update account' do
      put :update, params: { account: { name: 'Changed Title' }, id: account_1.id }
      expect(response).to have_http_status(:success)
      expect(account_1.reload.name).to eq('Changed Title')
    end

    it 'should not update account when validation fails' do
      put :update, params: { account: { name: '' }, id: account_1.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'DELETE #destroy' do
    it 'should destroy account' do
      expect {
        delete :destroy, params: { id: account_1.id }
      }.to change(Account, :count).by(-1)
    end

    it 'should not destroy account' do
      allow_any_instance_of(Account).to receive(:destroy).and_return(false)
      delete :destroy, params: { id: account_1.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end
end
