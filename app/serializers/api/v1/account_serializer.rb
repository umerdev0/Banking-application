# frozen_string_literal: true

module Api
  module V1
    class AccountSerializer < ActiveModel::Serializer
      attributes :id, :name, :bank, :balance

      def bank
        object.bank.name
      end

      def balance
        object.balance.to_f
      end
    end
  end
end
