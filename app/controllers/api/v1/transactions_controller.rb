# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :set_transaction, only: %i[show update destroy mark_duplicate]

      def index
        @transactions = Transaction.includes(:sender, :recipient).search(params[:search_by])
                                   .order_by(params[:order_by])
        render json: @transactions
      end

      def show
        render json: @transaction
      end

      def create
        @transaction = Transaction.new(transaction_params)
        save_transaction_with_response
      end

      def update
        @transaction.assign_attributes(transaction_params)
        save_transaction_with_response
      end

      def destroy
        if @transaction.destroy
          render json: @transaction
        else
          render_errors(@transaction)
        end
      end

      def mark_duplicate
        if @transaction.mark_duplicate
          render json: @transaction
        else
          render_errors(@transaction)
        end
      end

      private

      def set_transaction
        @transaction = Transaction.find(params[:id])
      end

      def transaction_params
        params.require(:transaction).permit(:description, :sender_id, :sender_type, :recipient_id,
                                            :recipient_type, :amount, :transaction_date)
      end

      def save_transaction_with_response
        if @transaction.save_with_locks
          render json: @transaction
        else
          render_errors(@transaction)
        end
      end
    end
  end
end
