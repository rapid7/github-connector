require 'rails_helper'

RSpec.describe Setup::RulesController, :type => :controller do

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      expect(response).to be_successful
    end
  end

  describe "PUT 'update'" do
    subject { put 'update', params: { settings: { rule_max_sync_age: 60 }}}

    it 'saves settings' do
      subject
      expect(Rails.application.settings.rule_max_sync_age).to eq(60)
    end
  end

end
