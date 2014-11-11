require 'rails_helper'

describe Rules::GithubMfa do
  subject(:rule) { Rules::GithubMfa.new(github_user) }
  let(:github_user) { build(:github_user_with_user) }
  let(:user) { github_user.user }
  let(:settings) { double }

  before do
    allow(described_class).to receive(:settings).and_return(settings)
  end

  it 'is valid when MFA is enabled' do
    github_user.mfa = true
    expect(rule).to be_valid
  end

  it 'is invaid when MFA is disabled' do
    github_user.mfa = false
    expect(rule).to_not be_valid
  end

  it 'is invalid when MFA is unknown' do
    github_user.mfa = nil
    expect(rule).to_not be_valid
  end

  it 'is required for external users' do
    expect(rule).to be_required_for_external
  end

  it 'returns an error message' do
    expect(rule.error_msg).to be_a(String)
    expect(rule.error_msg).to include('factor')
  end
end
