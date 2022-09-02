# frozen_string_literal: true

class Bank < ApplicationRecord
  acts_as_paranoid

  has_many :accounts, -> { with_deleted }, inverse_of: :bank, dependent: :destroy
  has_many :outgoing_transactions, as: :sender, class_name: :Transaction, dependent: nil
  has_many :incoming_transactions, as: :recipient, class_name: :Transaction, dependent: nil

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 30 }
end
