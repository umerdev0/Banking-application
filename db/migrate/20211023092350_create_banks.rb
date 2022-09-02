# frozen_string_literal: true

class CreateBanks < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'citext'
    create_table :banks do |t|
      t.citext :name, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
