require 'rails_helper'

describe Rules::LastLdapSync do
  subject(:rule) { described_class.new(github_user) }
  let(:user) { github_user.user }
  let(:github_user) { build(:github_user_with_user) }
  let(:settings) { double(rule_max_sync_age: max_sync_age) }

  before do
    allow(described_class).to receive(:settings).and_return(settings)
  end

  context 'with max sync setting' do
    let(:max_sync_age) { 86400 }

    it 'is enabled' do
      expect(described_class).to be_enabled
    end

    it 'is valid when Active Directory was recently synced' do
      user.last_ldap_sync = Time.now
      expect(rule).to be_valid
    end

    it 'is not valid when Active Directory sync is out of date' do
      user.last_ldap_sync = Time.now - 2.days
      expect(rule).to_not be_valid
    end

    it 'is not valid when Active Directory sync date is missing' do
      user.last_ldap_sync = nil
      expect(rule).to_not be_valid
    end

    it 'is not required for external users' do
      expect(rule).to_not be_required_for_external
    end

    describe '#error_msg' do
      it 'returns an error message if LDAP user doesn\'t exist' do
        github_user.user = nil
        expect(rule.error_msg).to include('user')
      end

      it 'returns an error message if Active Directory has never synced' do
        user.last_ldap_sync = nil
        expect(rule.error_msg).to include('never')
      end

      it 'returns an error message if Active Directory is too old' do
        user.last_ldap_sync = Time.now - 2.days
        expect(rule.error_msg).to include('old')
      end
    end

  end

  context 'without max sync setting' do
    let(:max_sync_age) { nil }

    it 'is not enabled' do
      expect(described_class).to_not be_enabled
    end
  end
end
