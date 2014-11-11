require 'rails_helper'

describe GithubAdmin do
  subject(:github) { GithubAdmin.new }

  context 'with GitHub' do

    def double_team(id, name, attrs={})
      double(id: id, name: name, to_h: attrs.merge(
        id: id,
        name: name,
        slug: name.parameterize.underscore,
        organization: {login: 'org1'}
      ))
    end

    def double_user(username, attrs={})
      double(login: username, to_h: attrs.merge(login: username))
    end

    let(:octokit) { double }
    let(:settings) { double(github_admin_token: 'footoken', github_orgs: orgs) }
    let(:orgs) { ['org1', 'org2'] }
    let(:users) {[
      double_user('hsimpson'),
      double_user('msimpson'),
      double_user('bsimpson'),
    ]}
    let(:mfa_disabled_users) {[
      double_user('bsimpson'),
    ]}
    let(:teams) {[
      double_team(1, 'My Team 1'),
      double_team(2, 'My Team 2'),
    ]}
    let(:team_members) { users[0..1] }

    before do
      allow(github).to receive(:octokit).and_return(octokit)
      allow(github).to receive(:settings).and_return(settings)
      allow(octokit).to receive(:organization_members).with(anything).and_return(users)
      allow(octokit).to receive(:organization_members).with(anything, {filter: '2fa_disabled'}).and_return(mfa_disabled_users)
      allow(octokit).to receive(:organization_teams).and_return(teams)
      allow(octokit).to receive(:team).and_return(teams.first)
      allow(octokit).to receive(:team_members).and_return(team_members)
    end

    it 'searches all configured organizations for users' do
      expect(octokit).to receive(:organization_members).with('org1').and_return(users)
      expect(octokit).to receive(:organization_members).with('org2').and_return(users)
      github.org_users
    end

    it 'adds :mfa_enabled attribute to user hashes' do
      users = github.org_users
      expect(users['hsimpson']).to have_key(:mfa_enabled)
      expect(users['hsimpson'][:mfa_enabled]).to eq(true)
      expect(users['bsimpson'][:mfa_enabled]).to eq(false)
    end

    it 'adds :orgs attribute to user hashes' do
      users = github.org_users
      expect(users['hsimpson']).to have_key(:orgs)
      expect(users['hsimpson'][:orgs]).to eq(['org1', 'org2'])
    end

    it 'adds organization to teams' do
      teams = github.teams
      expect(teams.values.first).to have_key(:organization)
      expect(teams.values.first[:organization]).to be_a(String)
    end

    it 'adds organization to individual teams' do
      team = github.team(1)
      expect(team).to have_key(:organization)
      expect(team[:organization]).to be_a(String)
    end

    it 'searches for team by id' do
      expect(octokit).to receive(:team).with(1).and_return(teams.first)
      github.team(1)
    end

    it 'searches for team with hash' do
      expect(octokit).to receive(:team).with(1).and_return(teams.first)
      github.team({id: 1})
    end

    it 'searches for team by slug' do
      team = github.team("my_team_1")
      expect(team).to be_a(Hash)
      expect(team[:name]).to eq('My Team 1')
    end

    it 'fetches team members' do
      team_members = github.team_members(1)
      expect(team_members).to_not be_empty
    end

    it 'checks MFA for a single user' do
      allow(octokit).to receive(:organization_member?).and_return(true)
      expect(github.user_mfa?('hsimpson')).to eq(true)
      expect(github.user_mfa?('bsimpson')).to eq(false)
    end

    it 'only checks MFA if user is a member of an organization' do
      expect(octokit).to receive(:organization_member?).and_return(false).at_least(1)
      expect(octokit).to_not receive(:organization_members)
      expect(github.user_mfa?('foouser')).to_not eq(true)
    end

    it 'uses cached users to query MFA if available' do
      github.org_users
      expect(octokit).to_not receive(:organization_members)
      expect(github.user_mfa?('hsimpson')).to eq(true)
      expect(github.user_mfa?('bsimpson')).to eq(false)
    end
  end

  it 'returns an Octokit client' do
    allow(github).to receive(:settings).and_return(double(github_admin_token: 'footoken'))
    octokit = github.octokit
    expect(octokit).to be_a(Octokit::Client)
    expect(octokit.access_token).to eq('footoken')
  end

  it 'auto paginates GitHub API responses' do
    allow(github).to receive(:settings).and_return(double(github_admin_token: 'footoken'))
    octokit = github.octokit
    expect(octokit.auto_paginate).to eq(true)
  end

  it 'references the application settings singleton' do
    expect(Rails.application).to receive(:settings).and_call_original
    expect(github.settings).to be_a(GithubConnector::Settings)
  end
end
