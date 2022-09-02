# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bank, type: :model do
  describe 'Association Tests' do
    it { should have_many(:accounts).dependent(:destroy) }
    it { should have_many(:outgoing_transactions).dependent(nil) }
    it { should have_many(:incoming_transactions).dependent(nil) }
  end

  describe 'Validation Tests' do
    before { create(:bank) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_most(30) }
  end

  describe 'Soft Deletion Tests' do
    subject { create(:bank, name: 'Test Bank') }
    include_examples 'soft deletion cases', Bank
  end
end
