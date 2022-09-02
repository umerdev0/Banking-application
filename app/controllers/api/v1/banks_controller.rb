# frozen_string_literal: true

module Api
  module V1
    class BanksController < ApplicationController
      before_action :set_bank, only: %i[show update destroy]

      def index
        render json: Bank.all
      end

      def show
        render json: @bank
      end

      def create
        @bank = Bank.new(bank_params)
        if @bank.save
          render json: @bank
        else
          render_errors(@bank)
        end
      end

      def update
        if @bank.update(bank_params)
          render json: @bank
        else
          render_errors(@bank)
        end
      end

      def destroy
        if @bank.destroy
          render json: @bank
        else
          render_errors(@bank)
        end
      end

      private

      def bank_params
        params.require(:bank).permit(:name)
      end

      def set_bank
        @bank = Bank.find(params[:id])
      end
    end
  end
end
