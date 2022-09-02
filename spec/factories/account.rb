# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::String.random(length: 3..12).tr("\u0000", '') }
    bank { create(:bank) }
    balance_cents { 0 }

    after(:create) do |account, _options|
      create(:transaction, sender: account.bank,
                           recipient: account,
                           transaction_date: Date.current,
                           amount_cents: 150_000)
    end
  end
end
