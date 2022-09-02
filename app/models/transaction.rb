# frozen_string_literal: true

class Transaction < ApplicationRecord
  attr_accessor :mutex_locked

  MUTEX_LOCK_OPTIONS = { block: 5, expire: 50 }.freeze

  has_paper_trail
  acts_as_paranoid

  include Orderable

  belongs_to :sender, -> { with_deleted }, polymorphic: true
  belongs_to :recipient, -> { with_deleted }, polymorphic: true

  validates :amount_cents, numericality: { greater_than_equal_to: 0 }
  validates :description, presence: true, length: { minimum: 3 }
  validates :transaction_date, presence: true

  validate :validate_participants,
           :validate_bank_of_participants, if: -> { sender_changed? || recipient_changed? }
  validate :validate_transaction_date_in_past, if: -> { transaction_date_changed? }
  validate :validate_sender_balance, if: -> { amount_cents_changed? && sender_type.eql?('Account') }
  validate :validate_updateability

  scope :pending, -> { where(pending: true) }
  scope :completed, -> { where(pending: false) }
  scope :non_duplicate, -> { where(duplicate: false) }
  scope :of_past, -> { where('transactions.transaction_date <= ?', Date.current) }
  scope :of_bank, lambda { |bank_id|
    bank = Bank.find_by(id: bank_id)
    where(sender: bank).or(where(recipient: bank))
                       .or(where(sender: bank.accounts)
                       .or(where(recipient: bank.accounts)))
  }
  scope :of_account, lambda { |account_id|
    where(sender_type: 'Account', sender_id: account_id).or(where(recipient_type: 'Account', recipient_id: account_id))
  }

  after_initialize :mark_pending, if: :new_record?
  before_destroy :check_pending_status
  after_save :mark_completed, if: -> { transaction_date_previously_changed? }

  monetize :amount_cents, as: 'amount'

  def self.search(search_params, records = self)
    if search_params&.dig(:account_id).present?
      records = records.of_account(search_params[:account_id])
    elsif search_params&.dig(:bank_id).present?
      records = records.of_bank(search_params[:bank_id])
    end

    records
  end

  def mark_completed
    return if transaction_date > Date.current || !pending?

    self.pending = false
    return true if save_with_locks && update_balance_of_participants

    throw :abort
  end

  def mark_duplicate
    if Transaction.where('created_at > ? AND created_at <= ?', created_at - 1.minute, created_at)
                  .or(Transaction.where('created_at >= ? AND created_at < ?', created_at, created_at - 1.minute))
                  .where(sender: sender, recipient: recipient, transaction_date: transaction_date,
                         amount_cents: amount_cents)
                  .where.not(id: id).exists?
      self.duplicate = true
      save_with_locks && update_balance_of_participants
    else
      errors.add(:base, I18n.t('messages.not_a_duplicate'))
      false
    end
  end

  def save_with_locks
    return save if mutex_locked

    operation_status = false
    sender_lock = RedisMutex.new("SenderType:#{sender_type}::Sender:#{sender_id}", MUTEX_LOCK_OPTIONS)
    recipient_lock = RedisMutex.new("RecipientType:#{recipient_type}::Recipient:#{recipient_id}", MUTEX_LOCK_OPTIONS)

    begin
      sender_lock.lock!
      recipient_lock.lock!
      self.mutex_locked = true

      operation_status = save
    rescue RedisMutex::LockError
      errors.add(:base, I18n.t('messages.failed_to_acquire_lock'))
    ensure
      self.mutex_locked = false
      sender_lock.unlock! if sender_lock.locked?
      recipient_lock.unlock! if recipient_lock.locked?
    end

    operation_status
  end

  private

  def sender_changed?
    sender_id_changed? || sender_type_changed?
  end

  def recipient_changed?
    recipient_id_changed? || recipient_type_changed?
  end

  def validate_transaction_date_in_past
    return if transaction_date >= Date.current

    errors.add(:base, I18n.t('messages.transaction_date_in_past'))
  end

  def validate_updateability
    return if (pending.eql?(true) || changes.except('pending').empty? || duplicate_changed?) &&
              (changes.except('duplicate').empty? || !duplicate?)

    errors.add(:base, I18n.t('messages.non_updatable_transaction'))
  end

  def validate_sender_balance
    return if sender.balance_cents >= amount_cents

    errors.add(:base, I18n.t('messages.insufficient_balance'))
  end

  def validate_participants
    return unless sender.eql?(recipient)

    errors.add(:base, I18n.t('messages.same_sender_and_recipient'))
  end

  def validate_bank_of_participants
    sender_bank_id = sender_type.eql?('Account') ? sender.bank_id : sender.id
    recipient_bank_id = recipient_type.eql?('Account') ? recipient.bank_id : recipient.id
    return if sender_bank_id.eql?(recipient_bank_id)

    errors.add(:base, I18n.t('messages.accounts_of_different_banks'))
  end

  def mark_pending
    self.pending = true
  end

  def check_pending_status
    return if pending?

    throw :abort
  end

  def update_balance_of_participants
    operation_status = true
    amount_changed = amount_cents * (duplicate? ? -1 : 1)
    operation_status = sender.update_balance_by_amount(amount_changed * -1) if sender_type.eql?('Account')

    if operation_status && recipient_type.eql?('Account')
      operation_status = recipient.update_balance_by_amount(amount_changed)
    end

    operation_status
  end
end
