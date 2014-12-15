require 'rails_helper'
require 'github_synchronizer'

describe GithubSynchronizer do

  subject(:synchronizer) { GithubSynchronizer.new }
  let(:github_admin) { double }
  let(:octokit) { double }
  let(:org_users) { {} }
  let(:teams) { {} }
  let(:team_members) { {} }

  before do
    allow(github_admin).to receive(:octokit).and_return(octokit)
    allow(github_admin).to receive(:org_users).and_return(org_users)
    allow(github_admin).to receive(:teams).and_return(teams)
    allow(github_admin).to receive(:team).and_return(teams.values.first)
    allow(github_admin).to receive(:team_members).and_return(team_members)

    # Mock methods that make real calls / send emails, etc.
    allow(GithubAdmin).to receive(:new).and_return(github_admin)
    allow_any_instance_of(GithubUser).to receive(:sync)
    allow_any_instance_of(GithubUser).to receive(:transition)
    allow_any_instance_of(GithubTeam).to receive(:sync)
    allow_any_instance_of(User).to receive(:sync)
  end

  describe '#sync_users' do
    let(:users) { create_list(:github_user, 1, id: 1337, login: 'hsimpson') }
    let(:org_users) {{
      'hsimpson' => {id: 1337, login: 'hsimpson', mfa_enabled: true},
      'msimpson' => {id: 7331, login: 'msimpson', mfa_enabled: true},
    }}

    it 'adds users' do
      expect(synchronizer.sync_users).to eq(true)
      expect(GithubUser.all).to_not be_empty
      expect(GithubUser.all.map(&:login)).to include('msimpson')
    end

    it 'removes Github users without corresponding app users' do
      create(:github_user, login: 'foouser')
      expect(synchronizer.sync_users).to eq(true)
      expect(GithubUser.where(login: 'foouser')).to be_empty
    end

    it 'does not remove Github users with corresponding app users' do
      user = create(:user)
      create(:github_user, login: 'foouser', user: user)
      expect(synchronizer.sync_users).to eq(true)
      expect(GithubUser.where(login: 'foouser')).to_not be_empty
    end

    it 'synchronizes the Github mfa the attribute' do
      user = users.first
      expect(synchronizer.sync_users).to eq(true)
      expect(user.reload.mfa).to eq(true)
    end

    it 'synchronizes users with tokens' do
      user = users.first
      user.token = 'footoken'
      user.save
      allow_any_instance_of(GithubUser).to receive(:sync) do |user|
        expect(user.login).to eq('hsimpson')
      end
      expect(synchronizer.sync_users).to eq(true)
    end

    it 'continues if errors occur' do
      allow(github_admin).to receive(:org_users).and_raise('foo error')
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors).to_not be_empty
    end

    it 'continues if errors occur in threads' do
      allow_any_instance_of(GithubUser).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved.new('record not saved'))
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors.first).to be_a(ActiveRecord::RecordNotSaved)
    end

    it 'counts sync errors as errors' do
      allow_any_instance_of(GithubUser).to receive(:sync_error).and_return('foo error')
      expect(synchronizer.sync_users).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors.first).to include('foo error')
    end

    it 'runs in threads according to thread_count' do
      synchronizer.thread_count = 2
      expect(Thread).to receive(:new).exactly(2).times.and_call_original
      synchronizer.sync_users
    end
  end

  describe '#sync_teams' do
    let(:teams) {{
      1 => {id: 1, slug: 'myteam', organization: 'myorg'},
      5 => {id: 5, slug: 'footeam', organization: 'myorg'},
    }}

    before do
      GithubTeam.create!(id: 5, slug: 'myoldslug')
    end

    it 'synchronizes each team' do
      sync_count = 0
      allow_any_instance_of(GithubTeam).to receive(:sync) { sync_count += 1 }
      expect(synchronizer.sync_teams).to eq(true)
      expect(sync_count).to eq(2)
    end

    it 'continues if errors occur' do
      allow(github_admin).to receive(:teams).and_raise('foo error')
      expect(synchronizer.sync_teams).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors).to_not be_empty
    end

    it 'continues if errors occur in threads' do
      allow_any_instance_of(GithubTeam).to receive(:sync).and_raise(ActiveRecord::RecordNotSaved.new('record not saved'))
      expect(synchronizer.sync_teams).to eq(false)
      expect(synchronizer.errors).to be_a(Array)
      expect(synchronizer.errors.first).to be_a(ActiveRecord::RecordNotSaved)
    end

    it 'runs in threads according to thread_count' do
      synchronizer.thread_count = 2
      expect(Thread).to receive(:new).exactly(2).times.and_call_original
      synchronizer.sync_teams
    end
  end

  describe '#run!' do
    let (:rate_limit) { double(remaining: 5000, resets_in: 3600) }

    before do
      allow(octokit).to receive(:rate_limit).and_return(rate_limit)
    end

    it 'synchronizes teams' do
      expect(synchronizer).to receive(:sync_teams)
      synchronizer.run!
    end

    it 'synchronizes users' do
      expect(synchronizer).to receive(:sync_users)
      synchronizer.run!
    end

    it 'returns true if successful' do
      expect(synchronizer.run!).to eq(true)
    end

    it 'returns false if errors occurred' do
      allow(github_admin).to receive(:teams).and_raise("foo error")
      expect(synchronizer.run!).to eq(false)
    end

    it 'checks rate limit' do
      expect(rate_limit).to receive(:remaining).and_return(10)
      expect(synchronizer.run!).to eq(false)
    end
  end

  describe '.run!' do
    before do
      allow_any_instance_of(GithubSynchronizer).to receive(:run!)
    end

    it 'runs the synchronizer' do
      expect_any_instance_of(GithubSynchronizer).to receive(:run!)
      instance = GithubSynchronizer.run!
    end

    it 'returns the synchronizer object' do
      expect(GithubSynchronizer.run!).to be_a(GithubSynchronizer)
    end
  end

end
