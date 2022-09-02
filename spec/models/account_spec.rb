# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'Association Tests' do
    it { should belong_to(:bank) }
    it { should have_many(:outgoing_transactions).dependent(nil) }
    it { should have_many(:incoming_transactions).dependent(nil) }
  end

  describe 'Validation Tests' do
    subject { create(:account, name: 'Account 1 Testing') }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:bank_id).case_insensitive }
    it { should validate_length_of(:name).is_at_most(30) }
    it { should validate_numericality_of(:balance_cents) }
  end

  describe 'Instance Method Tests' do
    describe '#all_transactions' do
      let!(:bank) { create(:bank) }
      let!(:account_1) { create(:account, bank: bank) }
      let!(:account_2) { create(:account, bank: bank) }
      let!(:transaction_1) { create(:transaction, sender: bank, recipient: account_1) }
      let!(:transaction_2) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_3) { create(:transaction, sender: account_2, recipient: account_1) }
      let!(:transaction_4) { create(:transaction, sender: bank, recipient: account_2) }

      it 'should include all transactions of account' do
        records = account_1.all_transactions
        expect(records).to include(transaction_1)
        expect(records).to include(transaction_2)
        expect(records).to include(transaction_3)
        expect(records).to_not include(transaction_4)
      end
    end

    describe '#update_balance_by_amount' do
      let!(:bank) { create(:bank) }
      let!(:account) { create(:account, bank: bank) }

      context 'when lock is successfully acquired' do
        it 'should update balance by given amount_cents' do
          expect {
            account.update_balance_by_amount(200)
          }.to change(account, :balance_cents).by(200)
        end
      end

      context 'when lock is failed to acquired' do
        it 'should not update balance and error' do
          allow_any_instance_of(RedisMutex).to receive(:lock!).and_raise(RedisMutex::LockError)
          expect {
            account.update_balance_by_amount(200)
          }.to change(account, :balance_cents).by(0)
          expect(account.errors.full_messages).to include(I18n.t('messages.failed_to_acquire_lock'))
        end
      end
    end
  end

  describe 'Soft Deletion Tests' do
    let!(:bank) { create(:bank) }
    subject { create(:account, bank: bank) }

    include_examples 'soft deletion cases', Account
  end
end
