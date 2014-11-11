require 'rails_helper'

describe GithubTeam do
  subject(:team) { described_class.new(id: 1) }

  context 'with GitHub' do
    let(:github_admin) { double('github_admin') }
    let(:gh_teams) {{
      1 => {id: 1, name: 'My Team 1', slug: 'my_team_1', organization: 'org1'},
      5 => {id: 5, name: 'My Team 5', slug: 'my_team_5', organization: 'org1'},
    }}
    let(:team_members) {{
      'hsimpson' => {login: 'hsimpson', name: 'Homer Simpson'},
      'msimpson' => {login: 'msimpson', name: 'Marge Simpson'},
    }}

    before do
      allow(team).to receive(:github_admin).and_return(github_admin)
      allow(github_admin).to receive(:teams).and_return(gh_teams)
      allow(github_admin).to receive(:team) do |team_id|
        gh_teams.values.find { |t| t[:id] == team_id || t[:slug] == team_id }
      end
      allow(github_admin).to receive(:team_members).and_return(team_members)
    end

    it 'synchronizes team information' do
      team.sync
      expect(team.name).to eq('My Team 1')
      expect(team.organization).to eq('org1')
      expect(team.slug).to eq('my_team_1')
    end

    it 'synchronizes added members' do
      create(:github_user, login: 'hsimpson')
      create(:github_user, login: 'msimpson')
      team.sync!
      expect(team.github_users.size).to eq(2)
      members = team.github_users.map { |t| t.login }
      expect(members).to include('hsimpson', 'msimpson')
    end

    it 'synchronizes removed members' do
      team.github_users << create(:github_user, login: 'foouser')
      team.sync
      members = team.github_users.map { |t| t.login }
      expect(members).to_not include('foouser')
    end

    it 'only saves if information changed' do
      team.sync
      expect(team).to_not receive(:save)
      expect(team).to_not receive(:save!)
      expect(team.sync).to eq(true)
    end

    it 'only saves if information changed' do
      team.sync
      expect(team).to_not receive(:save)
      expect(team).to_not receive(:save!)
      expect(team.sync).to eq(true)
    end
  end

  it 'returns a GithubAdmin client' do
    expect(team.github_admin).to be_a(GithubAdmin)
  end

  it 'returns a "full" slug' do
    team.organization = "org1"
    team.slug = "my_team_1"
    expect(team.full_slug).to eq("org1/my_team_1")
  end

  it 'finds by "full" slug' do
    team.organization = "org1"
    team.slug = "my_team_1"
    team.save

    found_team = described_class.find_by_full_slug('org1/my_team_1')
    expect(found_team).to be_a(GithubTeam)
    expect(found_team.id).to eq(team.id)
  end
end
