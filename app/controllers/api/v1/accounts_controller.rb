# frozen_string_literal: true

module Api
  module V1
    class AccountsController < ApplicationController
      before_action :set_account, only: %i[show update destroy]

      def index
        render json: Account.includes(:bank).order_by(params[:order_by])
      end

      def show
        render json: @account
      end

      def create
        @account = Account.new(account_params)
        if @account.save
          render json: @account
        else
          render_errors(@account)
        end
      end

      def update
        if @account.update(account_params)
          render json: @account
        else
          render_errors(@account)
        end
      end

      def destroy
        if @account.destroy
          render json: @account
        else
          render_errors(@account)
        end
      end

      private

      def account_params
        params.require(:account).permit(:name, :bank_id)
      end

      def set_account
        @account = Account.find(params[:id])
      end
    end
  end
end
