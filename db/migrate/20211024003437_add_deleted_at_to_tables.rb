# frozen_string_literal: true

class AddDeletedAtToTables < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :deleted_at, :datetime
    add_column :transactions, :deleted_at, :datetime
    add_column :banks, :deleted_at, :datetime
  end
end
