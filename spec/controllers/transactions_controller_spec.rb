# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::TransactionsController do
  let!(:bank) { create(:bank) }
  let!(:account_1) { create(:account, bank: bank) }
  let!(:account_2) { create(:account, bank: bank) }
  let!(:transaction) { create(:transaction, sender: account_1, recipient: account_2) }

  describe 'GET #index' do
    before { get :index }

    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end

    it 'JSON body response contains expected transactions' do
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(Transaction.all.count)
    end

    describe '#order_by' do
      let!(:bank) { create(:bank) }
      let!(:account) { create(:account, bank: bank) }
      let!(:transaction_1) { create(:transaction, sender: bank, recipient: account) }
      let!(:transaction_2) { create(:transaction, sender: bank, recipient: account) }
      let!(:transaction_3) { create(:transaction, sender: bank, recipient: account) }

      context 'when sequence is ascending order' do
        it 'should order as expected if attribute is a column' do
          expect(Transaction.all.order_by({ attribute: :amount_cents, sequence: :asc }).ids).to eq(
            Transaction.order(amount_cents: :asc).ids
          )
        end
      end

      context 'when sequence is ascending order' do
        it 'should order as expected' do
          expect(Transaction.all.order_by({ attribute: :amount_cents, sequence: :desc }).ids).to eq(
            Transaction.order(amount_cents: :desc).ids
          )
        end
      end

      context 'when attribute is an invalid column' do
        it 'should not order' do
          expect(Transaction.all.order_by({ attribute: :abc, sequence: :asc }).ids).to_not eq(
            Transaction.order(amount_cents: :asc).ids
          )
        end
      end

      context 'when sequence is invalid' do
        it 'should not order' do
          expect(Transaction.all.order_by({ attribute: :amount_cents, sequence: :abc }).ids).to_not eq(
            Transaction.order(amount_cents: :asc).ids
          )
        end
      end
    end
  end

  describe 'GET #show' do
    it 'should test show action to be success' do
      get :show, params: { id: transaction.id }
      expect(response).to have_http_status(:success)
    end

    it 'should render transaction' do
      get :show, params: { id: transaction.id }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(transaction.id)
    end

    it 'should render not transaction' do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'POST #create' do
    let(:valid_params) do
      { sender_id: bank.id,
        sender_type: 'Bank',
        recipient_id: account_1.id,
        recipient_type: 'Account',
        amount: 500,
        transaction_date: Date.current,
        description: 'Testing' }
    end

    let(:invalid_params) do
      { sender_id: bank.id,
        sender_type: 'Bank',
        recipient_id: account_1.id,
        recipient_type: 'Account',
        amount: 500,
        transaction_date: Date.yesterday }
    end

    it 'should create transaction' do
      expect {
        post :create, params: { transaction: valid_params }, as: :json
      }.to change(Transaction, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it 'should not create transaction when validation fails' do
      expect {
        post :create, params: { transaction: invalid_params }, as: :json
      }.to change(Transaction, :count).by(0)
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'PUT #update' do
    let!(:transaction) do
      create(:transaction, sender: account_1, recipient: account_2, transaction_date: Date.tomorrow)
    end

    it 'should update transaction' do
      put :update, params: { transaction: { amount: 500 }, id: transaction.id }
      expect(response).to have_http_status(:success)
      expect(transaction.reload.amount.to_i).to eq(500)
    end

    it 'should not update transaction when validation fails' do
      put :update, params: { transaction: { description: '' }, id: transaction.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'DELETE #destroy' do
    let!(:transaction) do
      create(:transaction, sender: account_1, recipient: account_2, transaction_date: Date.tomorrow)
    end

    it 'should destroy transaction' do
      expect {
        delete :destroy, params: { id: transaction.id }
      }.to change(Transaction, :count).by(-1)
    end

    it 'should not destroy transaction when validation fails' do
      transaction.update!(transaction_date: Date.current)
      expect {
        delete :destroy, params: { id: transaction.id }
      }.to change(Transaction, :count).by(0)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end
  end

  context 'PUT #mark_duplicate' do
    let!(:transaction) do
      create(:transaction, sender: account_1, recipient: account_2)
    end

    it 'should not mark as duplicate transaction when duplicate record does not exist' do
      put :mark_duplicate, params: { id: transaction.id }
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to_not be(nil)
    end

    it 'should mark as duplicate transaction when duplicate exists' do
      create(:transaction, sender: account_1, recipient: account_2, amount_cents: transaction.amount_cents,
                           created_at: transaction.created_at - 1.second)
      put :mark_duplicate, params: { id: transaction.id }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to be(nil)
      expect(transaction.reload.duplicate).to eq(true)
    end
  end
end
