require 'rails_helper'

describe Rules do
  it 'returns default rules' do
    rules = [
      Rules::Email,
      Rules::LastGithubSync,
      Rules::LastLdapSync,
      Rules::ActiveLdap,
      Rules::GithubMfa
    ]

    rules.each do |rule_klass|
      allow(rule_klass).to receive(:enabled?).and_return(true)
    end

    rules.each do |rule_klass|
      expect(Rules.enabled_rules).to include(rule_klass)
    end
  end

  it 'returns instantiated objects for a specific user' do
    user = build(:github_user)
    rule = Rules.for_github_user(user).first
    expect(rule).to be_a(Rules::Base)
    expect(rule.github_user).to eq(user)
  end

  describe Rules::Iterator do
    let(:user) { double(:user) }
    let(:rules) {[
      double(:rule1, name: 'rule1', valid?: false, required_for_external?: true),
      double(:rule2, name: 'rule2', valid?: false, required_for_external?: false),
      double(:rule3, name: 'rule3', valid?: true,  required_for_external?: true),
    ]}
    let(:iterator) { described_class.new(rules) }

    it 'filters for failing rules' do
      expect(iterator.failing.map(&:name)).to eq(%w(rule1 rule2))
    end

    it 'filters for passing rules' do
      expect(iterator.passing.map(&:name)).to eq(%w(rule3))
    end

    it 'filters for external rules' do
      expect(iterator.external.map(&:name)).to eq(%w(rule1 rule3))
    end

    it 'allows chaining filters' do
      expect(iterator.failing.external.map(&:name)).to eq(%w(rule1))
    end

    it 'adds filters to clones without filtering original' do
      iterator2 = iterator.dup
      expect(iterator2.external.map(&:name)).to eq(%w(rule1 rule3))
      expect(iterator.map(&:name)).to eq(%w(rule1 rule2 rule3))
    end
  end
end
