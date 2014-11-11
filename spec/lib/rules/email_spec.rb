require 'rails_helper'

describe Rules::Email do
  subject(:rule) { Rules::Email.new(github_user) }
  let(:github_user) { create(:github_user_with_emails, user: user) }
  let(:user) { create(:user) }
  let(:settings) { double(rule_email_regex: regex) }

  before do
    allow(described_class).to receive(:settings).and_return(settings)
  end

  context 'with email regex' do
    let(:regex) { '@example\.com$' }

    it 'is enabled' do
      expect(described_class).to be_enabled
    end

    it 'is valid when regex matches' do
      expect(rule).to be_valid
    end

    it "is not valid when regex doesn't match" do
      github_email = github_user.emails.last
      github_email.address = 'bsimpson@example.org'
      github_email.save
      expect(rule).to_not be_valid
    end

    it 'does not check ldap address' do
      user.email = 'bsimpson@example.org'
      expect(rule).to be_valid
    end

    it 'is not required for external users' do
      expect(rule).to_not be_required_for_external
    end

    it 'returns an error message' do
      github_email = github_user.emails.last
      github_email.address = 'bsimpson@example.org'
      github_email.save
      expect(rule.error_msg).to be_a(String)
      expect(rule.error_msg).to include('bsimpson@example.org')
    end
  end

  context 'without email regex' do
    let(:regex) { nil }

    it 'is not enabled' do
      expect(described_class).to_not be_enabled
    end
  end
end
