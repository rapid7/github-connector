require 'rails_helper'

describe Rules::LastGithubSync do
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

    it 'is valid when Github was recently synced' do
      github_user.last_sync_at = Time.now
      expect(rule).to be_valid
    end

    it 'is not valid when Github sync is out of date' do
      github_user.last_sync_at = Time.now - 2.days
      expect(rule).to_not be_valid
    end

    it 'is not valid when GitHub sync date is missing' do
      github_user.last_sync_at = nil
      expect(rule).to_not be_valid
    end

    it 'is required for external users' do
      expect(rule).to be_required_for_external
    end

    describe '#error_msg' do
      it 'returns an error message if GitHub user has never synced' do
        github_user.last_sync_at = nil
        expect(rule.error_msg).to include('never')
      end

      it 'returns an error message if GitHub user is too old' do
        github_user.last_sync_at = Time.now - 2.days
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
