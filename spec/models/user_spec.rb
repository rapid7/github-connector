require 'rails_helper'

describe User do

  subject(:user) { create(:user, username: username) }

  let(:username) { 'foouser' }
  let(:name) { 'Foo User' }
  let(:email) { 'foouser@example.com' }
  let(:user_account_control) { 512 }

  context 'with ldap' do
    let(:ldap) { double }
    let(:ldap_connection) { double(ldap: ldap) }
    let(:ldap_entry) {
      entry = Net::LDAP::Entry.new("cn=#{username},dc=example,dc=com")
      entry['sAMAccountName'] = username
      entry['mail'] = email
      entry['name'] = name
      entry['userAccountControl'] = user_account_control
      entry
    }

    before do
      user.save!
      allow(Devise::LDAP::Adapter).to receive(:ldap_connect).and_return(ldap_connection)
      allow(ldap).to receive(:search).and_return([])
      allow(user).to receive(:ldap_entry).and_return(ldap_entry)
    end

    {
      sAMAccountName: 'username',
      userPrincipalName: 'principal name',
      mail: 'email address',
    }.each do |attr, desc|
      it "finds by Active Directory #{desc}" do
        filter = Net::LDAP::Filter.eq(attr.to_s, 'fakesearch')
        expect(ldap).to receive(:search).with(filter: filter).and_return([ldap_entry])
        resource = described_class.find_for_ldap_authentication(username: 'fakesearch')
        expect(resource).to be_a(described_class)
        expect(resource.username).to eq(username)
      end
    end

    it 'finds by domain\username syntax' do
      resource = described_class.find_for_ldap_authentication(username: "DOMAIN\\#{username}")
      expect(resource).to be_a(described_class)
      expect(resource.username).to eq(username)
    end

    it 'synchronizes ldap data during authentication' do
      expect(user).to receive(:sync_from_ldap).and_return(true)
      user.after_ldap_authentication
    end

    it 'synchronizes name' do
      expect(user.name).to be_nil
      user.sync_from_ldap!
      expect(user.name).to eq(name)
    end

    it 'synchronizes email' do
      expect(user.email).to be_nil
      user.sync_from_ldap!
      expect(user.email).to eq(email)
    end

    it 'synchronizes userAccountControl' do
      expect(user.ldap_account_control).to be_nil
      user.sync_from_ldap!
      expect(user.ldap_account_control).to eq(user_account_control)
    end

    it 'updates the synchronization date' do
      expect(user.last_ldap_sync).to be_nil
      user.sync_from_ldap!
      expect(user.last_ldap_sync).to_not be_nil
    end

    it 'saves ldap errors during sync' do
      expect(user).to receive(:ldap_get_param).and_raise(Net::LDAP::LdapError)
      user.sync_from_ldap!
      expect(user.last_ldap_sync).to be_nil
      expect(user.ldap_sync_error).to_not be_nil
      expect(user.ldap_sync_error_at).to_not be_nil
    end

    it 'removes previous ldap errors after successful sync' do
      user.ldap_sync_error = 'fooerror'
      user.ldap_sync_error_at = Time.now
      user.save!
      user.sync_from_ldap!
      expect(user.ldap_sync_error).to be_nil
      expect(user.ldap_sync_error_at).to be_nil
    end

    it 'returns account control flags' do
      user.ldap_account_control = 512
      expect(user.ldap_account_control_flags).to eq([:normal_account])
      user.ldap_account_control = 514
      expect(user.ldap_account_control_flags).to eq([:account_disabled, :normal_account])
    end
  end

  context 'with Github users' do
    let(:github_users) { create_list(:github_user_with_emails, 2, user: user) }

    before do
      github_users
    end

    it 'calls sync on each Github user' do
      allow(user).to receive(:github_users).and_return(github_users)
      github_users.each do |github_user|
        expect(github_user).to receive(:sync).and_return(true)
      end
      user.sync_from_github!
    end

    it 'returns Github emails' do
      emails = user.github_emails
      expect(emails).to be_an(Array)
      expect(emails).to_not be_empty
      expect(emails).to include(/githubemail\d+@example.com/)
    end
  end

  describe '#sync!' do
    it 'synchronizes ldap and GitHub' do
      expect(user).to receive(:sync_from_ldap).and_return(true)
      expect(user).to receive(:sync_from_github).and_return(true)
      user.sync!
    end
  end
end
