require 'rails_helper'

describe Rules::Base do
  class TestRule < Rules::Base
  end

  subject(:rule) { TestRule.new(user) }
  let(:user) { double }

  it 'does not implement #result' do
    expect { rule.result }.to raise_error(NotImplementedError)
  end

  it 'notifies by default' do
    expect(rule.notify?).to eq(true)
  end

  it 'is required for external users by default' do
    expect(rule).to be_required_for_external
  end

  it 'converts class name to a rule name' do
    expect(rule.name).to eq('test_rule')
  end

  it 'references the application settings singleton' do
    expect(Rails.application).to receive(:settings).and_call_original
    expect(rule.settings).to be_a(GithubConnector::Settings)
  end

  it 'returns an error message' do
    expect(rule.error_msg).to be_a(String)
    expect(rule.error_msg).to_not be_empty
  end

  it 'is enabled by default' do
    expect(TestRule).to be_enabled
  end
end
