# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:bank_1) { create(:bank) }
  let(:bank_2) { create(:bank) }
  let(:account_1) { create(:account, bank: bank_1) }
  let(:account_2) { create(:account, bank: bank_1) }
  let(:account_3) { create(:account, bank: bank_2) }
  let(:account_4) { create(:account, bank: bank_2) }

  describe 'Association Tests' do
    it { should belong_to(:sender) }
    it { should belong_to(:recipient) }
  end

  describe 'Validation Tests' do
    it { should validate_presence_of(:transaction_date) }
    it { should validate_presence_of(:description) }
    it { should validate_numericality_of(:amount_cents) }
  end

  describe 'Custom Validation Tests' do
    describe '#same_sender_and_recipient' do
      let(:transaction) { build(:transaction, sender: account_1, recipient: account_2) }
      it 'should be valid if sender and recipient are not same' do
        expect(transaction.valid?).to be(true)
      end

      it 'should be invalid if sender and recipient are same' do
        transaction.recipient = account_1
        expect(transaction.valid?).to be(false)
        expect(transaction.errors.full_messages).to include(I18n.t('messages.same_sender_and_recipient'))
      end
    end

    describe '#bank_of_sender_and_recipient' do
      context 'when sender is Bank' do
        let(:transaction_1) { build(:transaction, sender: bank_1, recipient: account_1) }
        let(:transaction_2) { build(:transaction, sender: account_1, recipient: account_2) }
        let(:transaction_3) { build(:transaction, sender: bank_2, recipient: account_1) }
        let(:transaction_4) { build(:transaction, sender: account_1, recipient: account_3) }

        it 'should be valid if transaction is intra bank' do
          expect(transaction_1.valid?).to be(true)
          expect(transaction_2.valid?).to be(true)
        end

        it 'should be invalid if transaction is inter bank' do
          expect(transaction_3.valid?).to be(false)
          expect(transaction_3.errors.full_messages).to include(I18n.t('messages.accounts_of_different_banks'))
          expect(transaction_4.valid?).to be(false)
          expect(transaction_4.errors.full_messages).to include(I18n.t('messages.accounts_of_different_banks'))
        end
      end
    end

    describe '#transaction_date_not_in_past' do
      let(:transaction) do
        build(:transaction, sender: bank_1, recipient: account_1, transaction_date: Date.yesterday)
      end

      it 'should be invalid if transaction date is in the past' do
        expect(transaction.valid?).to be(false)
        expect(transaction.errors.full_messages).to include(I18n.t('messages.transaction_date_in_past'))
      end
    end

    describe '#sender_balance' do
      let(:transaction) { build(:transaction, sender: account_1, recipient: account_2) }

      it 'should be valid if sender has sufficient balance' do
        transaction.amount = account_1.balance
        expect(transaction.valid?).to be(true)
      end

      it 'should be invalid if sender has sufficient balance' do
        transaction.amount = account_1.balance.to_f + 1
        expect(transaction.valid?).to be(false)
        expect(transaction.errors.full_messages).to include(I18n.t('messages.insufficient_balance'))
      end
    end

    describe '#status_for_updation' do
      let(:transaction) do
        create(:transaction, sender: account_1, recipient: account_2, transaction_date: Date.tomorrow)
      end

      it 'should be valid if not completed and not duplicate' do
        transaction.amount_cents = 200
        expect(transaction.save).to be(true)
      end

      it 'should be invalid if completed' do
        transaction.update!(transaction_date: Date.current)
        transaction.amount_cents = 200
        expect(transaction.save).to be(false)
        expect(transaction.errors.full_messages).to include(I18n.t('messages.non_updatable_transaction'))
      end

      it 'should be invalid if duplicate' do
        transaction.duplicate = true
        transaction.save(validate: false)
        transaction.amount_cents = 200
        expect(transaction.save).to be(false)
        expect(transaction.errors.full_messages).to include(I18n.t('messages.non_updatable_transaction'))
      end
    end
  end

  describe 'Custom Scope Tests' do
    describe '#pending' do
      let!(:transaction_1) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_2) do
        create(:transaction, sender: account_2, recipient: account_1, transaction_date: Date.tomorrow)
      end

      it 'should include pending transactions only' do
        records = Transaction.pending
        expect(records).to include(transaction_2)
        expect(records).to_not include(transaction_1)
      end
    end

    describe '#completed' do
      let!(:transaction_1) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_2) do
        create(:transaction, sender: account_2, recipient: account_1, transaction_date: Date.tomorrow)
      end

      it 'should include completed transactions only' do
        records = Transaction.completed
        expect(records).to include(transaction_1)
        expect(records).to_not include(transaction_2)
      end
    end

    describe '#non_duplicate' do
      let!(:transaction_1) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_2) do
        create(:transaction, sender: account_2, recipient: account_1, transaction_date: Date.tomorrow)
      end

      it 'should include non-duplicated transactions only' do
        transaction_2.duplicate = true
        transaction_2.save(validate: false)
        records = Transaction.non_duplicate
        expect(records).to include(transaction_1)
        expect(records).to_not include(transaction_2)
      end
    end

    describe '#of_past' do
      let!(:transaction_1) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_2) { create(:transaction, sender: account_2, recipient: account_1) }
      let!(:transaction_3) do
        create(:transaction, sender: account_2, recipient: account_1, transaction_date: Date.tomorrow)
      end

      it 'should not include transactions with future date' do
        transaction_2.transaction_date = Date.yesterday
        transaction_2.save(validate: false)
        records = Transaction.of_past
        expect(records).to include(transaction_1)
        expect(records).to include(transaction_2)
        expect(records).to_not include(transaction_3)
      end
    end

    describe '#of_account' do
      let!(:transaction_1) { create(:transaction, sender: bank_1, recipient: account_1) }
      let!(:transaction_2) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_3) do
        create(:transaction, sender: bank_1, recipient: account_2, transaction_date: Date.tomorrow)
      end

      it 'should include transactions of given account only' do
        records = Transaction.of_account(account_1.id)
        expect(records).to include(transaction_1)
        expect(records).to include(transaction_1)
        expect(records).to_not include(transaction_3)
      end
    end

    describe '#of_bank' do
      let!(:transaction_1) { create(:transaction, sender: bank_1, recipient: account_1) }
      let!(:transaction_2) { create(:transaction, sender: account_1, recipient: account_2) }
      let!(:transaction_3) do
        create(:transaction, sender: bank_1, recipient: account_2, transaction_date: Date.tomorrow)
      end
      let!(:transaction_4) do
        create(:transaction, sender: bank_2, recipient: account_3, transaction_date: Date.tomorrow)
      end

      it 'should include transactions of given bank only' do
        records = Transaction.of_bank(bank_1.id)
        expect(records).to include(transaction_1)
        expect(records).to include(transaction_1)
        expect(records).to include(transaction_3)
        expect(records).to_not include(transaction_4)
      end
    end
  end

  describe 'Class Method Tests' do
    describe '#search' do
      context 'when account_id is given' do
        let!(:transaction_1) { create(:transaction, sender: bank_1, recipient: account_1) }
        let!(:transaction_2) { create(:transaction, sender: account_1, recipient: account_2) }
        let!(:transaction_3) do
          create(:transaction, sender: bank_1, recipient: account_2, transaction_date: Date.tomorrow)
        end

        it 'should include transactions of given account only' do
          records = Transaction.all.search({ account_id: account_1.id })
          expect(records).to include(transaction_1)
          expect(records).to include(transaction_1)
          expect(records).to_not include(transaction_3)
        end
      end

      context 'when bank_id is given' do
        let!(:transaction_1) { create(:transaction, sender: bank_1, recipient: account_1) }
        let!(:transaction_2) { create(:transaction, sender: account_1, recipient: account_2) }
        let!(:transaction_3) do
          create(:transaction, sender: bank_1, recipient: account_2, transaction_date: Date.tomorrow)
        end
        let!(:transaction_4) do
          create(:transaction, sender: bank_2, recipient: account_3, transaction_date: Date.tomorrow)
        end

        it 'should include transactions of given bank only' do
          records = Transaction.all.search({ bank_id: bank_1.id })
          expect(records).to include(transaction_1)
          expect(records).to include(transaction_1)
          expect(records).to include(transaction_3)
          expect(records).to_not include(transaction_4)
        end
      end
    end
  end

  describe 'Instance Method Tests' do
    describe '#mark_completed' do
      let!(:transaction) do
        create(:transaction, sender: account_1, recipient: account_2, transaction_date: Date.tomorrow)
      end

      it 'should not update status for future transaction' do
        expect(transaction.mark_completed).to be(nil)
      end

      it 'should not update if status is not pending' do
        transaction.pending = false
        transaction.save(validate: false)
        expect(transaction.mark_completed).to be(nil)
      end

      it 'should update if transaction is pending and not of future' do
        transaction.update!(transaction_date: Date.current)
        allow(transaction).to receive(:pending?).and_return(true)
        expect(transaction.mark_completed).to_not be(nil)
      end

      it 'should throw abort' do
        transaction.update!(transaction_date: Date.current)
        allow(transaction).to receive(:pending?).and_return(true)
        allow(transaction).to receive(:save).and_return(false)
        expect {
          transaction.mark_completed
        }.to throw_symbol(:abort)
      end
    end

    describe '#mark_duplicate' do
      let!(:transaction) { create(:transaction, sender: bank_1, recipient: account_1) }

      context 'when duplicate is not present' do
        it 'should add error to model' do
          transaction.mark_duplicate
          expect(transaction.errors.full_messages).to include(I18n.t('messages.not_a_duplicate'))
        end
      end

      context 'when duplicate is present' do
        it 'should add error to model' do
          allow(Transaction).to receive_message_chain(:where, :or, :where, :where, :not, :exists?).and_return(true)
          transaction.mark_duplicate
          expect(transaction.errors.full_messages).to_not include(I18n.t('messages.not_a_duplicate'))
          expect(transaction.duplicate).to eq(true)
        end
      end
    end

    describe '#save_with_locks' do
      let!(:transaction) do
        create(:transaction, sender: bank_1, recipient: account_1, transaction_date: Date.tomorrow)
      end

      context 'when lock is successfully acquired' do
        it 'should update transaction' do
          transaction.amount_cents = 350
          expect(transaction.save_with_locks).to be(true)
          expect(transaction.reload.amount_cents).to eq(350)
        end
      end

      context 'when lock is failed to acquired' do
        it 'should not update transaction and add error' do
          prev_updated_at = transaction.updated_at
          allow_any_instance_of(RedisMutex).to receive(:lock!).and_raise(RedisMutex::LockError)
          expect(transaction.save_with_locks).to be(false)
          expect(transaction.errors.full_messages).to include(I18n.t('messages.failed_to_acquire_lock'))
          expect(transaction.reload.updated_at).to eq(prev_updated_at)
        end
      end
    end
  end

  describe 'Callback Tests' do
    describe '#set_status' do
      context 'when transaction date is in future' do
        let!(:transaction) do
          create(:transaction, sender: bank_1, recipient: account_1, transaction_date: Date.tomorrow)
        end

        it 'should set pending to true' do
          expect(transaction.pending?).to be(true)
        end
      end

      context 'when transaction date is not in future' do
        let!(:transaction) { create(:transaction, sender: bank_1, recipient: account_1) }

        it 'should set pending to false' do
          expect(transaction.pending?).to be(false)
        end
      end
    end

    describe '#check_pending_status' do
      let!(:transaction) do
        create(:transaction, sender: bank_1, recipient: account_1, transaction_date: Date.tomorrow)
      end

      it 'should destroy pending transactions' do
        expect(transaction.destroy).to_not be(false)
      end

      it 'should throw abort on destroying completed transactions' do
        transaction.update!(transaction_date: Date.current)
        expect(transaction.destroy).to be(false)
        expect { transaction.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end
  end

  describe 'Soft Deletion Tests' do
    subject { create(:transaction, sender: account_1, recipient: account_2, transaction_date: Date.tomorrow) }
    include_examples 'soft deletion cases', Transaction
  end
end
