# frozen_string_literal: true

bank = Bank.create!(name: 'Seed Bank')

acc1 = bank.accounts.create!(name: 'Seed Account 1')
acc2 = bank.accounts.create!(name: 'Seed Account 2')
acc3 = bank.accounts.create!(name: 'Seed Account 3')

Transaction.create!(sender: bank, recipient: acc1, transaction_date: Date.current,
                    amount: 150_000, description: 'Initial balance')
Transaction.create!(sender: bank,  recipient: acc2, transaction_date: Date.current,
                    amount: 250_000, description: 'Initial balance')
Transaction.create!(sender: bank,  recipient: acc3, transaction_date: Date.current,
                    amount: 350_000, description: 'Initial balance')
