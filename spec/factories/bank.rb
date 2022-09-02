# frozen_string_literal: true

FactoryBot.define do
  factory :bank do
    name { Faker::String.random(length: 3..12).tr("\u0000", '') }
  end
end
