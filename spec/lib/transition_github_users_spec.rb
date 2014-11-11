require 'rails_helper'
require 'transition_github_users'

describe TransitionGithubUsers do

  subject(:executor) { TransitionGithubUsers.new(github_users) }
  let(:github_admin) { double }
  let(:github_users) { nil }
  let(:github_teams) { [] }

  before do
    Rails.application.settings.enforce_rules = true

    # Mock methods that make real calls / send emails, etc.
    allow(GithubAdmin).to receive(:new).and_return(github_admin)
    allow_any_instance_of(GithubUser).to receive(:sync)
    allow_any_instance_of(GithubUser).to receive(:transition)
    allow_any_instance_of(GithubUser).to receive(:remove_from_organizations).and_return(github_teams)
    allow_any_instance_of(GithubUser).to receive(:remove_from_internal_teams).and_return(github_teams)
    allow_any_instance_of(User).to receive(:sync)
  end

  context 'with_users' do
    let(:github_users) { create_list(:github_user, 10) }

    describe '#transition_users' do
      it 'calls transition for each user' do
        github_users.each do |user|
          expect(user).to receive(:transition)
        end
        expect(executor.transition_users).to eq(true)
      end

      it 'continues if errors occur' do
        expect(executor).to receive(:github_users).and_raise('foo error')
        expect(executor.transition_users).to eq(false)
        expect(executor.errors).to be_a(Array)
        expect(executor.errors).to_not be_empty
      end

      it 'continues if errors occur in threads' do
        expect(github_users[2]).to receive(:transition).and_raise('foo error')
        expect(executor.transition_users).to eq(false)
        expect(executor.errors).to be_a(Array)
        expect(executor.errors).to_not be_empty
      end

      it 'tracks transitioned users' do
        expect(github_users[2]).to receive(:transition).and_return(:disable)
        executor.transition_users
        expect(executor.transitions).to be_a(Array)
        expect(executor.transitions.count).to eq(1)
        expect(executor.transitions.first).to eq(github_users[2])
      end

      it 'runs in threads according to thread_count' do
        executor.thread_count = 2
        expect(Thread).to receive(:new).exactly(2).times.and_call_original
        executor.transition_users
      end
    end

    describe '#enforce_state' do
      let(:disabled_github_user) { github_users[1] }
      let(:external_github_user) { github_users[2] }
      let(:github_teams) { create_list(:github_team, 4) }

      before do
        disabled_github_user.state = :disabled
        disabled_github_user.teams << github_teams
        disabled_github_user.save!
        allow(GithubUser).to receive(:disabled).and_return([disabled_github_user])

        external_github_user.state = :external
        external_github_user.teams << github_teams
        external_github_user.save!
        allow(GithubUser).to receive(:external).and_return([external_github_user])
      end

      it 'calls remove_from_organizations' do
        expect(disabled_github_user).to receive(:remove_from_organizations).and_return(github_teams)
        github_users.each do |user|
          next if user == disabled_github_user
          expect(user).to_not receive(:remove_from_organizations)
        end
        executor.enforce_state
      end

      it 'calls remove_from_internal_teams for external users' do
        expect(external_github_user).to receive(:remove_from_internal_teams).and_return(github_teams)
        github_users.each do |user|
          next if user == external_github_user
          expect(user).to_not receive(:remove_from_internal_teams)
        end
        executor.enforce_state
      end

      it 'stores removed teams in disabled_teams' do
        executor.enforce_state
        expect(disabled_github_user.disabled_teams).to eq(github_teams)
        expect(external_github_user.disabled_teams).to eq(github_teams)
      end

      it 'does not run if enforce_rules is false' do
        Rails.application.settings.enforce_rules = false
        expect(disabled_github_user).to_not receive(:remove_from_organizations)
        expect(external_github_user).to_not receive(:remove_from_internal_teams)
        executor.enforce_state
      end

      it 'continues if errors occur' do
        expect(GithubUser).to receive(:disabled).and_raise('foo error')
        expect(executor.enforce_state).to eq(false)
        expect(executor.errors).to be_a(Array)
        expect(executor.errors).to_not be_empty
      end

      it 'continues if errors occur in threads' do
        expect(disabled_github_user).to receive(:remove_from_organizations).and_raise('foo error')
        expect(external_github_user).to receive(:remove_from_internal_teams).and_raise('foo error')
        expect(executor.enforce_state).to eq(false)
        expect(executor.errors).to be_a(Array)
        expect(executor.errors).to_not be_empty
      end
    end

    describe '#run!' do
      it 'disables users' do
        expect(executor).to receive(:transition_users)
        executor.run!
      end

      it 'enforces user state' do
        expect(executor).to receive(:enforce_state)
        executor.run!
      end

      it 'returns true if successful' do
        expect(executor.run!).to eq(true)
      end

      it 'returns false if errors occurred' do
        allow(github_users[1]).to receive(:transition).and_raise('foo error')
        expect(executor.run!).to eq(false)
      end
    end
  end

  it 'runs with all users by default' do
    create(:github_user_with_user, state: :enabled)
    create(:github_user, state: :enabled)
    create(:github_user_with_user, state: :unknown)
    create(:github_user_with_user, state: :disabled)
    executor = TransitionGithubUsers.new
    expect(executor.github_users.count).to eq(4)
  end

  it 'reloads ActiveRecord scopes' do
    user = create(:github_user, state: :enabled)
    executor = TransitionGithubUsers.new(GithubUser.where(state: 'enabled'))
    expect(executor.github_users.size).to eq(1)
    user.state = :disabled
    user.save!
    expect_any_instance_of(GithubUser).to_not receive(:sync)
    executor.run!
  end

  describe '.run!' do
    before do
      allow_any_instance_of(TransitionGithubUsers).to receive(:run!)
    end

    it 'runs the executor' do
      expect_any_instance_of(TransitionGithubUsers).to receive(:run!)
      instance = TransitionGithubUsers.run!
    end

    it 'returns the executor object' do
      expect(TransitionGithubUsers.run!).to be_a(TransitionGithubUsers)
    end
  end

end
