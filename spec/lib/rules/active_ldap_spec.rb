require 'rails_helper'

describe Rules::ActiveLdap do
  subject(:rule) { Rules::ActiveLdap.new(github_user) }
  let(:user) { github_user.user }
  let(:github_user) { build(:github_user_with_user) }
  let(:settings) { double }

  before do
    allow(described_class).to receive(:settings).and_return(settings)
  end

  it 'is valid for a normal account' do
    user.ldap_account_control = 512
    expect(rule).to be_valid
  end

  it 'is not valid when account is disabled' do
    user.ldap_account_control = 514
    expect(rule).to_not be_valid
  end

  it 'is not valid without a User' do
    github_user.user = nil
    expect(rule).to_not be_valid
  end

  it 'does not notify' do
    expect(rule).to_not be_notify
  end

  it 'is not required for external users' do
    expect(rule).to_not be_required_for_external
  end

  describe '#error_msg' do
    it 'returns a generic error message' do
      github_user.user = nil
      expect(rule.error_msg).to be_a(String)
      expect(rule.error_msg).to include('criteria')
    end

    it 'returns an account disabled error message' do
      user.ldap_account_control = User::AccountControl::ACCOUNT_DISABLED
      expect(rule.error_msg).to include('disabled')
    end

    #it 'returns a password expired error message' do
    #  user.ldap_account_control = User::AccountControl::PASSWORD_EXPIRED
    #  expect(rule.error_msg).to include('password')
    #end
  end
end
