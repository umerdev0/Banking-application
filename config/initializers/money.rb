# frozen_string_literal: true

MoneyRails.configure do |config|
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.locale_backend = :currency
end
