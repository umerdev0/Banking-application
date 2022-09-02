# frozen_string_literal: true

module Api
  module V1
    class TransactionSerializer < ActiveModel::Serializer
      attributes :id, :sender, :recipient, :description, :transaction_date, :amount, :duplicate, :pending

      def sender
        object.sender.name
      end

      def recipient
        object.recipient.name
      end

      def amount
        object.amount.to_f
      end
    end
  end
end
