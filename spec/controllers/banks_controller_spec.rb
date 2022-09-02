# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::BanksController do
  let!(:bank) { create(:bank) }

  describe 'GET #index' do
    before { get :index }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'JSON body response contains expected banks' do
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(Bank.all.count)
    end
  end

  describe 'GET #show' do
    it 'should test show action to be success' do
      get :show, params: { id: bank.id }
      expect(response).to have_http_status(:success)
    end

    it 'should render bank' do
      get :show, params: { id: bank.id }
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(bank.id)
    end

    it 'should render not render bank' do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'POST #create' do
    let(:valid_params) do
      { name: 'Test Bank' }
    end

    let(:invalid_params) do
      { name: '' }
    end

    it 'should create bank' do
      expect {
        post :create, params: { bank: valid_params }, as: :json
      }.to change(Bank, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it 'should not create bank when validation fails' do
      expect {
        post :create, params: { bank: invalid_params }, as: :json
      }.to change(Bank, :count).by(0)
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'PUT #update' do
    it 'should update bank' do
      put :update, params: { bank: { name: 'Changed Title' }, id: bank.id }
      expect(response).to have_http_status(:success)
      expect(bank.reload.name).to eq('Changed Title')
    end

    it 'should not update bank when validation fails' do
      put :update, params: { bank: { name: '' }, id: bank.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'DELETE #destroy' do
    it 'should destroy bank' do
      expect {
        delete :destroy, params: { id: bank.id }
      }.to change(Bank, :count).by(-1)
    end

    it 'should not destroy account' do
      allow_any_instance_of(Bank).to receive(:destroy).and_return(false)
      delete :destroy, params: { id: bank.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to include('errors')
    end
  end
end
