# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.references :sender, polymorphic: true, null: false
      t.references :recipient, polymorphic: true, null: false
      t.date :transaction_date, null: false
      t.boolean :duplicate, null: false, default: false
      t.boolean :pending, null: false, default: true
      t.text :description, null: false, default: ''
      t.integer :amount_cents, unsigned: true, null: false, default: 0
      t.timestamps
    end
  end
end
