require 'rails_helper'

describe LdapSynchronizer do

  subject(:synchronizer) { LdapSynchronizer.new([user]) }
  let(:user) { build(:user) }

  before do
    allow(user).to receive(:sync_from_ldap).and_return(true)
  end

  describe '#sync_users' do
    it 'calls sync_from_ldap' do
      expect(user).to receive(:sync_from_ldap).and_return(true)
      expect(synchronizer.sync_users).to eq(true)
    end

    it 'continues if errors occur' do
      allow(synchronizer).to receive(:users).and_raise('foo error')
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors).to_not be_empty
    end

    it 'continues if errors occur in threads' do
      allow(user).to receive(:sync_from_ldap).and_raise('foo error')
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors).to_not be_empty
    end

    it 'counts sync errors as errors' do
      allow(user).to receive(:ldap_sync_error).and_return('foo error')
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors.first).to include('foo error')
    end
  end

  describe '#run!' do
    it 'synchronizes users' do
      expect(synchronizer).to receive(:sync_users)
      synchronizer.run!
    end

    it 'returns true if successful' do
      expect(synchronizer.run!).to eq(true)
    end

    it 'returns false if errors occurred' do
      allow(user).to receive(:sync_from_ldap).and_raise("foo error")
      expect(synchronizer.run!).to eq(false)
    end
  end
end
