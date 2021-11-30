require 'rails_helper'

RSpec.describe GithubUsersController, :type => :controller do
  before do
    sign_in(user)
    configured
  end

  let(:user) { create(:admin_user) }
  let(:github_user) { create(:github_user) }

  describe "GET index" do
    it "returns http success" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET show" do
    it "returns http success" do
      get :show, params: { id: github_user.login }
      expect(response).to be_successful
    end
  end

end
