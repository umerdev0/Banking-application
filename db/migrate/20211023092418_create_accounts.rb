# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :accounts do |t|
      t.citext :name, null: false
      t.references :bank, null: false, foreign_key: true
      t.integer :balance_cents, unsigned: true, null: false, default: 0
      t.index %i[name bank_id], unique: true
      t.timestamps
    end
  end
end
