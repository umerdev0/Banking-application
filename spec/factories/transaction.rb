# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    sender { create(:account) }
    recipient { create(:account) }
    amount_cents { Faker::Number.number(digits: 4) }
    description { 'Test desc' }
    transaction_date { Date.current }
    duplicate { false }
    pending { true }
  end
end
