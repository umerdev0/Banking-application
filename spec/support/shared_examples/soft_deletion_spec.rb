# frozen_string_literal: true

RSpec.shared_examples 'soft deletion cases' do |klass|
  before do
    subject.destroy!
  end

  it 'should not be available with without deleted' do
    expect(klass.without_deleted.find_by(id: subject.id)).to be(nil)
  end

  it 'should be available with without deleted' do
    expect(klass.only_deleted.find_by(id: subject.id)).to eq(subject)
  end
end
