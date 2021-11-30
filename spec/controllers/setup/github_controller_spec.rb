require 'rails_helper'

RSpec.describe Setup::GithubController, :type => :controller do

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_successful
    end

    it 'sets default orgs' do
      Rails.application.settings.company = 'Example'
      get 'edit'
      expect(assigns(:settings).github_orgs).to eq(['example'])
    end

    it 'sets default teams' do
      Rails.application.settings.company = 'Example'
      get 'edit'
      expect(assigns(:settings).github_default_teams).to eq(['example-employees'])
    end
  end

  describe "PUT 'update'" do
    let(:settings) { {github_orgs: 'foocompany'} }
    subject { put 'update', params: { settings: settings }}

    it 'saves settings' do
      subject
      expect(Rails.application.settings.github_orgs).to eq(['foocompany'])
    end

    context 'with connect_github parameter' do
      it 'calls github_admin action' do
        expect(controller).to receive(:github_admin) { controller.redirect_to('foobar') }
        put 'update', params: { settings: settings, connect_github: 'connect' }
      end
    end
  end

end
