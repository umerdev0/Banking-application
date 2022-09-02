# frozen_string_literal: true

class Account < ApplicationRecord
  has_paper_trail ignore: [:name]
  acts_as_paranoid

  include Orderable

  belongs_to :bank, -> { with_deleted }, inverse_of: :accounts

  has_many :outgoing_transactions, as: :sender, class_name: :Transaction, dependent: nil
  has_many :incoming_transactions, as: :recipient, class_name: :Transaction, dependent: nil

  validates :name, presence: true, uniqueness: { scope: :bank_id, case_sensitive: false },
                   length: { maximum: 30 }
  validates :balance_cents, numericality: { greater_than_equal_to: 0 }

  monetize :balance_cents, as: 'balance'

  def all_transactions
    incoming_transactions.or(outgoing_transactions).order(:transaction_date)
  end

  def update_balance_by_amount(changed_amount_cents)
    mutex = RedisMutex.new("Account:#{id}", { block: 60, expire: 40 })

    begin
      mutex.lock!
      self.balance_cents += changed_amount_cents
      operation_status = save
    rescue RedisMutex::LockError
      errors.add(:base, I18n.t('messages.failed_to_acquire_lock'))
      operation_status = false
    ensure
      mutex.unlock! if mutex.locked?
    end

    operation_status
  end
end
