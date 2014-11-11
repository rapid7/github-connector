require 'rails_helper'

describe Rules::GithubOauth do
  subject(:rule) { Rules::GithubOauth.new(github_user) }
  let(:github_user) { build(:github_user_with_user) }
  let(:user) { github_user.user }
  let(:settings) { double }

  before do
    allow(described_class).to receive(:settings).and_return(settings)
    github_user.token = 'footoken'
  end

  it 'is invalid when GitHub token is missing' do
    github_user.token = nil
    expect(rule).to_not be_valid
  end

  it 'is invalid with notoken GitHub error' do
    github_user.sync_error = 'notoken'
    expect(rule).to_not be_valid
  end

  it 'is invalid with unauthorized GitHub error' do
    github_user.sync_error = 'unauthorized'
    expect(rule).to_not be_valid
  end

  it 'is valid with no errors' do
    expect(rule).to be_valid
  end

  it 'is valid with GitHub server error' do
    github_user.sync_error = 'internal_server_error'
    expect(rule).to be_valid
  end

  it 'is not required for external users' do
    expect(rule).to_not be_required_for_external
  end

  it 'returns an error message when a token is missing' do
    github_user.token = nil
    expect(rule.error_msg).to be_a(String)
    expect(rule.error_msg.downcase).to include('missing')
  end

  it 'returns an error message when a token is missing' do
    github_user.sync_error = 'unauthorized'
    expect(rule.error_msg).to be_a(String)
    expect(rule.error_msg.downcase).to include('invalid')
  end
end
