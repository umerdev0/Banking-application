# frozen_string_literal: true

class ProcessPendingTransactionsWorker
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: :default

  def perform
    Transaction.pending.where('transaction_date <= ?', Date.current).find_each do |transaction|
      logger.info 'Failed to process transaction!' unless transaction.mark_completed
    end
  end
end
