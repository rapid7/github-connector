require 'rails_helper'

RSpec.describe Setup::CompanyController, :type => :controller do

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_success
    end
  end

  describe "PUT 'update'" do
    subject { put 'update', params: { settings: { company: 'foocompany' }}}

    it 'saves settings' do
      subject
      expect(Rails.application.settings.company).to eq('foocompany')
    end
  end

end
