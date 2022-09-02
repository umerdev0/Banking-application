# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe ProcessPendingTransactionsWorker, type: :worker do
  context 'testing worker' do
    it 'should enqueque worker' do
      expect {
        ProcessPendingTransactionsWorker.perform_async
      }.to change(described_class.jobs, :size).by(1)
    end
  end

  describe 'functionality spec' do
    let!(:date) { Date.tomorrow }
    let(:bank) { create(:bank) }
    let(:account_1) { create(:account, bank: bank) }
    let(:account_2) { create(:account, bank: bank) }
    let!(:transaction_1) do
      create(:transaction, sender: bank, recipient: account_1, transaction_date: date)
    end

    let!(:transaction_2) do
      create(:transaction, sender: account_1, recipient: account_2, transaction_date: date)
    end

    let!(:transaction_3) do
      create(:transaction, sender: bank, recipient: account_1, transaction_date: date.succ)
    end

    let!(:transaction_4) do
      create(:transaction, sender: account_1, recipient: account_2, transaction_date: date.succ)
    end

    it 'should mark transactions as completed' do
      Timecop.freeze(date) do
        expect {
          ProcessPendingTransactionsWorker.new.perform
        }.to change(Transaction.pending, :count).by(-2)
      end
    end
  end
end
