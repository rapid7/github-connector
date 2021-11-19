require 'rails_helper'

RSpec.describe ConnectController, :type => :controller do
  before do
    sign_in(user)
    configured
  end

  let(:user) { create(:user) }
  let(:settings) { double.as_null_object }

  before do
    allow(Rails.application).to receive(:settings).and_return(settings)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it 'sets a new ConnectGithubUserStatus' do
      get 'index'
      connect_status = assigns(:connect_status)
      expect(connect_status).to be_a(ConnectGithubUserStatus)
      expect(connect_status).to be_new_record
    end
  end

  describe "GET 'status'" do
    let(:connect_status) { ConnectGithubUserStatus.create(user: user) }

    it 'returns http success' do
      get 'status', params: { id: connect_status.id }
      expect(response).to be_successful
    end

    context 'with another user' do
      let(:connect_status) { ConnectGithubUserStatus.create(user: create(:user)) }

      it 'returns http forbidden' do
        get 'status', params: { id: connect_status.id }
        expect(response).to be_forbidden
      end
    end

  end

  describe "GET 'start'" do
    subject { get :start }

    before do
      allow(settings).to receive(:github_client_id).and_return('fooclient')
      allow(settings).to receive(:github_client_secret).and_return('foosecret')
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

    it 'requests user scopes from Settings.github_user_admin_oauth_scope' do
      expect(settings).to receive(:github_user_oauth_scope).and_return('foo:one,bar:two')
      subject
      expect(redirect_params).to include('scope' => 'foo:one,bar:two')
    end

    it 'sets the callback url to the auth_code action' do
      subject
      expect(redirect_params).to include('redirect_uri' => 'http://test.host/connect/auth_code')
    end

    it 'includes a CSRF state parameter' do
      subject
      expect(redirect_params).to include('state')
    end
  end

  describe "GET 'auth_code'" do
    subject { get :auth_code, params: { code: code, state: state }}
    let(:state) { 'foostate' }
    let(:code) { 'foocode' }
    #let(:oauth) { double('oauth', auth_code: double(get_token: oauth_token)) }
    #let(:oauth_token) { double('oauth_token', token: 'footoken') }
    #let(:octokit) { double('octokit', user: ghuser) }
    #let(:ghuser) { double(id: 1337, login: 'githubuser') }

    before do
      allow(controller).to receive(:oauth_authenticity_token).and_return(state)
      #allow(controller).to receive(:oauth_client).and_return(oauth)
      #allow_any_instance_of(GithubUser).to receive(:sync!) { |ghu| ghu.save! }
      #allow_any_instance_of(GithubUser).to receive(:add_to_organizations).and_return(true)
      #allow(Octokit::Client).to receive(:new).and_return(octokit)
    end

    it 'redirects to status' do
      expect(subject).to redirect_to(/\/connect\/\d+/)
    end

    it 'starts a ConnectGithubUserJob' do
      expect(ConnectGithubUserJob).to receive(:perform_later) do |status|
        expect(status.oauth_code).to eq(code)
      end
      subject
    end

    it 'rejects invalid CSRF token' do
      expect(controller).to receive(:oauth_authenticity_token).and_return('wrongtoken')
      expect { subject }.to raise_error(ActionController::InvalidAuthenticityToken)
    end
  end
end
