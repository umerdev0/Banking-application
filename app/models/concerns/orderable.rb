# frozen_string_literal: true

# this concern is mean't to be extended not included inside a model
module Orderable
  extend ActiveSupport::Concern

  included do
    scope :order_by, lambda { |order_params|
      attribute = order_params&.dig(:attribute)
      sequence = order_params&.dig(:sequence)&.upcase
      return self if column_names.exclude?(attribute.to_s) || %w[ASC DESC].exclude?(sequence.to_s)

      order("#{attribute} #{sequence}")
    }
  end
end
