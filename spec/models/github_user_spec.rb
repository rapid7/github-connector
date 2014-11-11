require 'rails_helper'

describe GithubUser do
  subject(:user) { create(:github_user) }

  context 'with GitHub' do
    let(:github_admin) { double('github_admin', octokit: admin_octokit) }
    let(:admin_octokit) { double('admin-octokit') }
    let(:octokit) { double('octokit', user: gh_user, emails: gh_emails, rate_limit: double) }
    let(:gh_login) { 'foouser-gh' }
    let(:gh_user) { double('gh_user', login: gh_login) }
    let(:gh_emails) {[
      {email: 'foouser@example.com', primary: true, verified: true},
      {email: 'foouser@example.org', primary: false, verified: true},
    ]}

    before do
      user.token = 'footoken'
      allow(user).to receive(:github_admin).and_return(github_admin)
      allow(user).to receive(:octokit).and_return(octokit)
    end

    it 'synchronizes GitHub username' do
      user.sync!
      expect(user.login).to eq(gh_login)
    end

    it 'synchronizes GitHub emails' do
      user.sync!
      emails = user.emails.map(&:address)
      expect(emails).to include('foouser@example.com')
      expect(emails).to include('foouser@example.org')
    end

    it 'removes old emails during synchronization' do
      user.save!
      user.emails.create!(address: 'foouser2@example.org')
      user.sync!
      expect(user.emails).to_not include('foouser2@example.org')
    end

    it 'updates the synchronization date' do
      expect(user.last_sync_at).to be_nil
      user.sync!
      expect(user.last_sync_at).to_not be_nil
    end

    it 'checks for a valid token' do
      expect(user.valid_token?).to eq(true)
    end

    it 'detects revoked token' do
      expect(octokit).to receive(:rate_limit).and_raise(Octokit::Unauthorized)
      expect(user.valid_token?).to eq(false)
    end

    it 'saves GitHub API errors during sync' do
      expect(octokit).to receive(:user).and_raise(Octokit::Unauthorized)
      user.sync!
      expect(user.last_sync_at).to be_nil
      expect(user.sync_error).to eq('unauthorized')
      expect(user.sync_error_at).to_not be_nil
    end

    it 'does not sync when GitHub token is missing' do
      user.token = nil
      user.sync!
      expect(user.last_sync_at).to be_nil
      expect(user.sync_error).to eq('notoken')
    end

    it 'removes previous GitHub API errors after successful sync' do
      user.sync_error = 'fooerror'
      user.sync_error_at = Time.now
      user.save!
      user.sync!
      expect(user.sync_error).to be_nil
      expect(user.sync_error_at).to be_nil
    end

    describe '#organizations' do
      let(:teams) { [
        create(:github_team, organization: 'fooorg1'),
        create(:github_team, organization: 'fooorg2'),
      ] }

      before do
        teams.each do |team|
          user.teams << team
        end
      end

      it 'returns organizations' do
        expect(user.organizations).to eq(['fooorg1', 'fooorg2'])
      end
    end

    describe '#remove_from_organizations' do
      before do
        allow(admin_octokit).to receive(:remove_organization_member).and_return(true)
      end

      it 'removes user from all Github organizations' do
        teams = create_list(:github_team, 3)
        user.teams << teams
        Rails.application.settings.github_orgs = ['org1', 'org2']
        expect(admin_octokit).to receive(:remove_organization_member).with('org1', user.login).and_return(true)
        expect(admin_octokit).to receive(:remove_organization_member).with('org2', user.login).and_return(true)
        removed_teams = user.remove_from_organizations
        expect(user.teams).to be_empty
        expect(removed_teams).to be_an(Array)
        expect(removed_teams.count).to eq(3)
      end
    end

    describe '#remove_from_internal_teams' do
      before do
        allow(admin_octokit).to receive(:remove_team_member).and_return(true)
      end

      it 'removes user from Github teams' do
        teams = create_list(:github_team, 2)
        user.teams << teams
        expect(admin_octokit).to receive(:remove_team_member).exactly(2).and_return(true)
        removed_teams = user.remove_from_internal_teams
        expect(removed_teams).to be_a(Array)
        expect(removed_teams.count).to eq(2)
      end

      it 'ignores external teams' do
        teams = create_list(:github_team, 2)
        user.teams << teams
        Rails.application.settings.github_external_teams = [teams[1].slug]
        removed_teams = user.remove_from_internal_teams
        expect(removed_teams).to be_a(Array)
        expect(removed_teams.count).to eq(1)
        expect(removed_teams.first.slug).to_not eq(teams[1].slug)
      end
    end

    describe '#add_to_organizations' do
      let(:orgs) { %w{org1 org2} }
      let(:settings) { Rails.application.settings }
      let(:check_mfa_team) { build(:github_team, id: 100, slug: 'check-mfa') }
      let(:default_team) { build(:github_team, id: 101, slug: 'employees') }

      before do
        settings.github_orgs = orgs
        settings.github_check_mfa_team = check_mfa_team.slug
        settings.github_default_teams = [default_team.slug]
        allow(GithubTeam).to receive(:find_by_full_slug).with(/check-mfa/).and_return(check_mfa_team)
        allow(GithubTeam).to receive(:find_by_full_slug).with(/employees/).and_return(default_team)

        allow(github_admin).to receive(:user_mfa?).and_return(true)
        allow(admin_octokit).to receive(:add_team_membership)
        allow(octokit).to receive(:update_organization_membership)
        allow(admin_octokit).to receive(:remove_team_member)
        allow(user).to receive(:failing_rules).and_return([])
      end

      context 'with new users' do
        before do
          allow(admin_octokit).to receive(:organization_member?).and_return(false)
        end

        it 'adds users to organizations' do
          expect(admin_octokit).to receive(:add_team_membership).with(check_mfa_team.id, user.login).exactly(orgs.count).times
          expect(octokit).to receive(:update_organization_membership).exactly(orgs.count).times
          user.add_to_organizations
        end

        it 'checks MFA status' do
          expect(github_admin).to receive(:user_mfa?)
          user.add_to_organizations
        end

        it 'adds to default teams' do
          expect(user).to receive(:add_to_teams).with([default_team.slug])
          user.add_to_organizations
        end
      end

      context 'with existing users' do
        before do
          allow(admin_octokit).to receive(:organization_member?).and_return(true)
        end

        it 'does not try to add to organization' do
          expect(admin_octokit).to_not receive(:add_team_membership).with(check_mfa_team.id, user.login)
          expect(octokit).to_not receive(:update_organization_membership)
          user.add_to_organizations
        end

        it 'adds to default teams' do
          expect(user).to receive(:add_to_teams).with([default_team.slug])
          user.add_to_organizations
        end

        it 'checks MFA' do
          user.mfa = false
          expect(github_admin).to receive(:user_mfa?).and_return(true)
          user.add_to_organizations
          expect(user.mfa).to eq(true)
        end
      end
    end

    describe '#add_to_teams' do
      let(:github_team1) { create(:github_team, id: 101, organization: 'org1', slug: 'footeam') }
      let(:github_team2) { create(:github_team, id: 102, organization: 'org2', slug: 'footeam') }
      let(:github_team3) { create(:github_team, id: 103, organization: 'org1', slug: 'barteam') }

      it 'adds GithubTeam objects' do
        expect(admin_octokit).to receive(:add_team_membership).with(github_team1.id, user.login)
        user.add_to_team(github_team1)
      end

      it 'adds teams using full slugs' do
        expect(admin_octokit).to receive(:add_team_membership).with(github_team1.id, user.login)
        user.add_to_team('org1/footeam')
      end

      it 'adds teams using unqualified slugs' do
        expect(admin_octokit).to receive(:add_team_membership).with(github_team1.id, user.login)
        expect(admin_octokit).to receive(:add_team_membership).with(github_team2.id, user.login)
        user.add_to_team('footeam')
      end

      it 'adds mixed GithubTeam, slug and full slugs' do
        expect(admin_octokit).to receive(:add_team_membership).with(github_team1.id, user.login)
        expect(admin_octokit).to receive(:add_team_membership).with(github_team2.id, user.login)
        expect(admin_octokit).to receive(:add_team_membership).with(github_team3.id, user.login)
        user.add_to_teams(github_team1, 'org2/footeam', 'barteam')
      end

      it 'accepts an array' do
        expect(admin_octokit).to receive(:add_team_membership).with(github_team1.id, user.login)
        expect(admin_octokit).to receive(:add_team_membership).with(github_team2.id, user.login)
        user.add_to_teams([github_team1, github_team2])
      end
    end

    describe '#add_back_disabled_teams' do
      let(:github_team1) { build(:github_team, id: 101, organization: 'org1', slug: 'footeam') }
      let(:github_team2) { build(:github_team, id: 102, organization: 'org2', slug: 'footeam') }

      before do
        user.disabled_teams = [github_team1, github_team2]
        allow(admin_octokit).to receive(:add_team_membership)
      end

      it 'adds the user to previously disabled teams' do
        expect(user).to receive(:add_to_teams).with(user.disabled_teams)
        user.add_back_disabled_teams
      end

      it 'returns the added teams' do
        expect(user.add_back_disabled_teams).to eq([github_team1, github_team2])
      end

      it 'clears the disabled teams' do
        user.add_back_disabled_teams
        expect(user.disabled_teams).to be_empty
      end

      it 'does nothing if there are no disabled teams' do
        user.disabled_teams.clear
        expect(user.add_back_disabled_teams).to eq([])
      end
    end
  end

  it 'returns an Octokit client' do
    user.token = 'footoken'
    octokit = user.octokit
    expect(octokit).to be_a(Octokit::Client)
    expect(octokit.access_token).to eq('footoken')
  end

  it 'returns a GithubAdmin client' do
    expect(user.github_admin).to be_a(GithubAdmin)
  end

  describe '#do_enable' do
    let(:transition) { double.as_null_object }

    it 'calls add_back_disabled_teams' do
      expect(user).to receive(:add_back_disabled_teams)
      user.send(:do_enable, transition)
    end
  end

  describe '#do_disable' do
    let(:transition) { double.as_null_object }

    it 'calls remove_from_organizations' do
      Rails.application.settings.enforce_rules = true
      expect(user).to receive(:remove_from_organizations).and_return([])
      user.send(:do_disable, transition)
    end

    it 'remembers disabled teams' do
      Rails.application.settings.enforce_rules = true
      teams = build_list(:github_team, 2)
      expect(user).to receive(:remove_from_organizations).and_return(teams)
      user.send(:do_disable, transition)
      expect(user.disabled_teams).to eq(teams)
    end

    it 'does not remove users when enforce_rules is false' do
      Rails.application.settings.enforce_rules = false
      expect(user).to_not receive(:remove_from_organizations)
      user.send(:do_disable, transition)
    end
  end

  describe '#do_notify_disabled' do
    let(:transition) { double.as_null_object }

    let(:mail) { double('Mail') }

    before do
      user.user = build(:user)
      allow(mail).to receive(:deliver_now)
      allow(mail).to receive(:deliver_later)
    end

    it 'sends an access revoked mail' do
      Rails.application.settings.enforce_rules = true
      expect(UserMailer).to receive(:access_revoked).and_return(mail)
      user.send(:do_notify_disabled, transition)
    end

    it 'does not send email when not enforcing rules' do
      Rails.application.settings.enforce_rules = false
      expect(UserMailer).to_not receive(:access_revoked)
      user.send(:do_notify_disabled, transition)
    end
  end

  describe '#do_restrict' do
    let(:transition) { double.as_null_object }

    it 'calls remove_from_internal_teams' do
      Rails.application.settings.enforce_rules = true
      expect(user).to receive(:remove_from_internal_teams).and_return([])
      user.send(:do_restrict, transition)
    end

    it 'remembers removed teams' do
      Rails.application.settings.enforce_rules = true
      teams = build_list(:github_team, 2)
      expect(user).to receive(:remove_from_internal_teams).and_return(teams)
      user.send(:do_restrict, transition)
      expect(user.disabled_teams).to eq(teams)
    end

    it 'does not remove users when enforce_rules is false' do
      Rails.application.settings.enforce_rules = false
      expect(user).to_not receive(:remove_from_internal_teams)
      user.send(:do_restrict, transition)
    end
  end

  describe '#do_notify_restricted' do
    let(:transition) { double.as_null_object }

    let(:mail) { double('Mail') }

    before do
      user.user = build(:user)
      allow(mail).to receive(:deliver_now)
      allow(mail).to receive(:deliver_later)
    end

    it 'sends an access revoked mail' do
      Rails.application.settings.enforce_rules = true
      expect(UserMailer).to receive(:access_revoked).and_return(mail)
      user.send(:do_notify_restricted, transition)
    end

    it 'does not send email when not enforcing rules' do
      Rails.application.settings.enforce_rules = false
      expect(UserMailer).to_not receive(:access_revoked)
      user.send(:do_notify_restricted, transition)
    end
  end

  context 'state' do
    class MockRule < Rules::Base
    end

    let(:rules) { [MockRule, MockRule] }
    let(:state) { :unknown }

    before do
      allow(Rules).to receive(:enabled_rules).and_return(rules)
      allow_any_instance_of(MockRule).to receive(:result).and_return(result)

      # Prevent do* methods from doing anything
      %i(do_disable do_notify_disabled do_enable do_restrict do_notify_restricted).each do |meth|
        allow(user).to receive(meth)
      end

      user.state = state
      user.save!
    end

    context 'with failing rules' do
      let(:result) { false }

      it 'has failing rules' do
        expect(user.failing_rules.count).to eq(rules.count)
      end

      it 'has no passing rules' do
        expect(user.passing_rules).to be_empty
      end

      context 'when enabled' do
        let(:state) { :enabled }

        it 'executes the disable event' do
          expect(user).to receive(:disable)
          user.transition
        end

        it 'executes the restrict event' do
          team = build(:github_team)
          allow(team).to receive(:external?).and_return(true)
          allow(user).to receive(:teams).and_return([team])
          allow_any_instance_of(MockRule).to receive(:required_for_external?).and_return(false)
          expect(user).to receive(:restrict)
          user.transition
        end

        describe '#disable' do
          it 'calls do_disable' do
            expect(user).to receive(:do_disable).with(kind_of(StateMachine::Transition))
            user.disable
          end

          it 'does not allow disabling excluded users' do
            Rails.application.settings.github_exclude_users = [user.login]
            expect(user).to_not receive(:do_disable)
            expect(user.disable).to eq(false)
          end

          it 'calls do_notify_disabled with failing notify rules' do
            allow_any_instance_of(MockRule).to receive(:notify?).and_return(true)
            expect(user).to receive(:do_notify_disabled).with(kind_of(StateMachine::Transition))
            user.disable
          end

          it 'does not call do_notify_disabled without failing notify rules' do
            allow_any_instance_of(MockRule).to receive(:notify?).and_return(false)
            expect(user).to_not receive(:do_notify_disabled).with(kind_of(StateMachine::Transition))
            user.disable
          end
        end

        describe '#restrict' do
          it 'calls do_restrict' do
            expect(user).to receive(:do_restrict).with(kind_of(StateMachine::Transition))
            user.restrict
          end

          it 'does not allow restricting excluded users' do
            Rails.application.settings.github_exclude_users = [user.login]
            expect(user).to_not receive(:do_restrict)
            expect(user.restrict).to eq(false)
          end

          it 'calls do_notify_restricted with failing notify rules' do
            allow_any_instance_of(MockRule).to receive(:notify?).and_return(true)
            expect(user).to receive(:do_notify_restricted).with(kind_of(StateMachine::Transition))
            user.restrict
          end

          it 'does not call do_notify_restricted without failing notify rules' do
            allow_any_instance_of(MockRule).to receive(:notify?).and_return(false)
            expect(user).to_not receive(:do_notify_restricted).with(kind_of(StateMachine::Transition))
            user.restrict
          end
        end
      end

      context 'when disabled' do
        let(:state) { :disabled }

        it 'does not execute an event' do
          expect(user).to_not receive(:disable)
          expect(user).to_not receive(:enable)
          user.transition
        end
      end

      context 'when unknown' do
        let(:state) { :unknown }

        it 'executes the disable event' do
          expect(user).to receive(:disable)
          user.transition
        end
      end
    end

    context 'without failing rules' do
      let(:result) { true }

      it 'has passing rules' do
        expect(user.passing_rules.count).to eq(rules.count)
      end

      it 'has no failing rules' do
        expect(user.failing_rules).to be_empty
      end

      context 'when enabled' do
        let(:state) { :enabled }

        it 'does not execute an event' do
          expect(user).to_not receive(:enable)
          expect(user).to_not receive(:disable)
          user.transition
        end
      end

      context 'when disabled' do
        let(:state) { :disabled }

        it 'executes enable event' do
          expect(user).to receive(:enable)
          user.transition
        end

        describe '#enable' do
          it 'calls do_enable' do
            expect(user).to receive(:do_enable).with(kind_of(StateMachine::Transition))
            user.transition
          end
        end
      end

      context 'when unknown' do
        let(:state) { :unknown }

        it 'executes the enable event' do
          expect(user).to receive(:enable)
          user.transition
        end

        it 'executes the exclude event' do
          allow(user).to receive(:global_excluded_user?).and_return(true)
          expect(user).to receive(:exclude)
          user.transition
        end
      end
    end
  end

end
