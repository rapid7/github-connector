require 'rails_helper'

RSpec.describe Setup::EmailController, :type => :controller do

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_success
    end

    it 'sets default email from company name' do
      allow(request).to receive(:host).and_return('localhost')
      Rails.application.settings.company = 'Example Corp'
      get 'edit'
      expect(assigns(:settings).email_from).to eq('github@example_corp.com')
    end

    it 'sets default email from url domain' do
      allow(request).to receive(:host).and_return('foocorp.com')
      get 'edit'
      expect(assigns(:settings).email_from).to eq('github@foocorp.com')
    end
  end

  describe "PUT 'update'" do
    subject { put 'update', params: { settings: {smtp_address: 'localhost'} } }

    it 'saves settings' do
      subject
      expect(Rails.application.settings.smtp_address).to eq('localhost')
    end
  end

end
