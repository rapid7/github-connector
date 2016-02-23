require 'rails_helper'

describe GithubConnector::Settings do

  subject(:settings) { GithubConnector::Settings.new }

  describe '#apply_to_action_mailer' do
    it 'applies config to ActionMailer::Base' do
      settings.smtp_address = 'foohost'
      settings.email_base_url = 'https://localhost:443/'
      settings.email_from = 'github@fooemail'
      settings.email_reply_to = ''
      settings.apply_to_action_mailer
      expect(ActionMailer::Base.smtp_settings[:address]).to eq('foohost')
      expect(ActionMailer::Base.default_url_options).to eq({host: 'localhost', protocol: 'https'})
      expect(ActionMailer::Base.default[:from]).to eq('github@fooemail')
      expect(ActionMailer::Base.default.keys).to_not include(:reply_to)
    end
  end

  describe '#email_keys' do
    it 'returns a list of email keys' do
      expect(settings.email_keys).to eq(%i(email_base_url email_from email_reply_to))
    end
  end

  describe '#email_config' do
    before do
      Setting.create(key: :email_from, value: 'fooemail@example.com')
    end

    it 'returns hash with email_ key prefixes removed' do
      config = settings.email_config
      expect(config).to have_key(:from)
      expect(config).to_not have_key(:email_from)
    end
  end

  describe '#github_admin_oauth_scope' do
    it 'includes the user scope' do
      expect(settings).to receive(:github_user_oauth_scope).and_return('foouser:fooscope')
      expect(settings.github_admin_oauth_scope).to include('foouser:fooscope')
    end

    it 'includes admin:org' do
      expect(settings.github_admin_oauth_scope).to include('admin:org')
    end
  end

  describe '#github_user_oauth_scope' do
    it 'includes required scopes' do
      expect(settings.github_user_oauth_scope).to include('user:email')
      expect(settings.github_user_oauth_scope).to include('read:public_key')
      expect(settings.github_user_oauth_scope).to include('write:org')
    end
  end

  describe '#ldap_keys' do
    it 'returns a list of ldap keys' do
      expect(settings.ldap_keys).to eq(%i(ldap_host ldap_port ldap_ssl ldap_admin_user ldap_admin_password ldap_attribute ldap_base))
    end
  end

  describe '#ldap_config' do
    before do
      Setting.create(key: :ldap_host, value: 'localhost')
    end

    it 'returns hash with ldap_ key prefixes removed' do
      config = settings.ldap_config
      expect(config).to have_key('host')
      expect(config).to_not have_key('ldap_host')
    end
  end

  describe '#smtp_keys' do
    it 'returns a list of smtp keys' do
      expect(settings.smtp_keys).to eq(%i(smtp_address smtp_port smtp_enable_starttls_auto smtp_user_name smtp_password smtp_authentication smtp_domain))
    end
  end

  describe '#smtp_config' do
    before do
      Setting.create(key: :smtp_address, value: 'localhost')
    end

    it 'returns hash with smtp_ key prefixes removed' do
      config = settings.smtp_config
      expect(config).to have_key(:address)
      expect(config).to_not have_key(:smtp_address)
    end
  end
end
