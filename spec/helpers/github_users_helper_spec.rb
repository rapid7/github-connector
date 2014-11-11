require 'rails_helper'

describe GithubUsersHelper do
  describe '#github_user_state_label' do
    let(:github_user) { build(:github_user) }

    it 'adds danger label for disabled users' do
      github_user.state = 'disabled'
      html = github_user_state_label(github_user)
      expect(html).to include('label-danger')
    end

    it 'adds info label for external users' do
      github_user.state = 'external'
      html = github_user_state_label(github_user)
      expect(html).to include('label-info')
    end

    it 'adds info label for excluded users' do
      github_user.state = 'excluded'
      html = github_user_state_label(github_user)
      expect(html).to include('label-info')
    end

    it 'adds warning label for unknown users' do
      github_user.state = 'unknown'
      html = github_user_state_label(github_user)
      expect(html).to include('label-warning')
    end

    it 'adds success label for enabled users' do
      github_user.state = 'enabled'
      html = github_user_state_label(github_user)
      expect(html).to include('label-success')
    end
  end
end
