require "rails_helper"

RSpec.describe UserMailer, :type => :mailer do

  before do
    Rails.application.settings.email_base_url = 'http://localhost:3000'
  end

  describe '#access_revoked' do
    subject(:mail) { UserMailer.access_revoked(user, github_user) }

    let(:user) { build(:user) }
    let(:github_user) { build(:github_user, user: user) }

    it 'renders subject' do
      expect(mail.subject).to eq('GitHub Access Revoked')
    end

    it 'renders html' do
      expect(mail).to be_multipart
      expect(mail.html_part.body).to include('GitHub access revoked!')
    end

    it 'renders plaintext' do
      expect(mail).to be_multipart
      expect(mail.text_part.body).to include('GitHub access revoked!')
    end
  end
end
