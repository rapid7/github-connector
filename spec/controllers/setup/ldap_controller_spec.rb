require 'rails_helper'

RSpec.describe Setup::LdapController, :type => :controller do

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_successful
    end

    it 'redirects to settings if application is already configured' do
      Rails.application.settings.configured = true
      get 'edit'
      expect(response).to redirect_to(controller: '/settings', action: :edit)
    end

    it 'sets development defaults for localhost' do
      request.set_header("HTTP_HOST", 'localhost')
      get 'edit'
      expect(assigns(:settings).ldap_base).to eq('dc=example,dc=com')
    end
  end

  describe "PUT 'update'" do
    subject { put 'update', params: { settings: { ldap_host: 'foohost', ldap_port: 3389 }}}
    let(:ldap) { double('ldap', bind: true).as_null_object }

    before do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
    end

    it 'saves settings' do
      subject
      expect(Rails.application.settings.ldap_host).to eq('foohost')
    end

    it 'tests ldap connection before saving' do
      expect(ldap).to receive(:bind).and_return(false)
      expect(subject).to_not be_redirect
      expect(assigns(:error)).to_not be_nil
    end
  end
end
