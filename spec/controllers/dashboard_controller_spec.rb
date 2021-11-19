require 'rails_helper'

RSpec.describe DashboardController, :type => :controller do
  before do
    sign_in
    configured
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_successful
    end

    it 'redirects to setup wizard if application is not configured' do
      Rails.application.settings.configured = false
      get 'index'
      expect(response).to redirect_to(setup_url)
    end

    it 'returns a http error if an LDAP authentication error occurs' do
      allow(controller).to receive(:index).and_raise(DeviseLdapAuthenticatable::LdapException)
      get 'index'
      expect(response).to have_http_status(500)
    end
  end

end
