require 'rails_helper'

RSpec.describe SettingsController, :type => :controller do
  before do
    sign_in(user)
    configured
  end

  let(:user) { create(:admin_user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_success
    end
  end

  describe "PUT 'update'" do
    subject { put 'update', settings: settings }
    let(:ldap) { double('ldap', bind: true).as_null_object }
    let(:settings) {{
      ldap_host: 'foohost',
      ldap_port: 3389,
      github_orgs: "org1\r\norg2",
    }}

    before do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
    end

    it 'redirects to the edit page' do
      expect(subject).to redirect_to(controller: :settings, action: :edit)
    end

    it 'saves settings' do
      subject
      expect(Rails.application.settings.ldap_host).to eq('foohost')
    end

    it 'converts organizations list to an array' do
      subject
      expect(Rails.application.settings.github_orgs).to eq(['org1', 'org2'])
    end

    it 'tests ldap connection before saving' do
      expect(ldap).to receive(:bind).and_return(false)
      expect(subject).to_not be_redirect
      expect(assigns(:error)).to_not be_nil
    end

    it 'handles ldap errors' do
      expect(ldap).to receive(:bind).and_raise(Net::LDAP::LdapError)
      expect(subject).to_not be_redirect
      expect(assigns(:error)).to_not be_nil
    end

    context 'with connect_github parameter' do
      it "calls github_admin action" do
        expect(controller).to receive(:github_admin) { controller.redirect_to('foobar') }
        put 'update', settings: settings, connect_github: 'connect'
      end
    end
  end

  describe "GET 'github_admin'" do
    subject { get :github_admin }
    let(:settings) { double.as_null_object }

    before do
      allow(Rails.application).to receive(:settings).and_return(settings)
      allow(settings).to receive(:github_client_id).and_return('fooclient')
      allow(settings).to receive(:github_client_secret).and_return('foosecret')
      allow(controller).to receive(:load_settings)
    end

    def redirect_params
      uri = URI.parse(response['Location'])
      CGI.parse(uri.query).inject({}) do |memo, (key, val)|
        memo[key] = val.length == 1 ? val.first : val
        memo
      end
    end

    it "redirects to GitHub's OAuth authorization page" do
      expect(subject).to redirect_to(%r(^https://github.com/login/oauth/authorize))
      expect(response['Location']).to include('client_id=fooclient')
    end

    it 'requests org:admin scope' do
      subject
      expect(redirect_params).to include('scope' => 'user:email,read:public_key,write:org,admin:org')
    end

    it 'sets the callback url to the github_auth_code action' do
      subject
      expect(redirect_params).to include('redirect_uri' => 'http://test.host/settings/github_auth_code')
    end

    it 'includes a CSRF state parameter' do
      subject
      expect(redirect_params).to include('state')
    end
  end

  describe "GET 'github_auth_code'" do
    subject { get :github_auth_code, state: state }
    let(:state) { 'foostate' }
    let(:oauth) { double('oauth', auth_code: double(get_token: oauth_token)) }
    let(:oauth_token) { double('oauth_token', token: 'footoken') }
    let(:octokit) { double('octokit', user: ghuser) }
    let(:ghuser) { double(id: 7337, login: 'githubuser') }

    before do
      allow(controller).to receive(:oauth_authenticity_token).and_return(state)
      allow(controller).to receive(:oauth_client).and_return(oauth)
      allow_any_instance_of(GithubUser).to receive(:sync!)
      allow(Octokit::Client).to receive(:new).and_return(octokit)
    end

    it 'redirects to edit' do
      expect(subject).to redirect_to(controller: 'settings', action: 'edit')
    end

    it 'stores the GitHub token' do
      subject
      expect(Rails.application.settings.github_admin_token).to eq(oauth_token.token)
    end

    it 'rejects invalid CSRF token' do
      expect(controller).to receive(:oauth_authenticity_token).and_return('wrongtoken')
      expect { subject }.to raise_error(ActionController::InvalidAuthenticityToken)
    end
  end
end
