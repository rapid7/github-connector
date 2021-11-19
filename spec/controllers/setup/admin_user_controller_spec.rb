require 'rails_helper'

RSpec.describe Setup::AdminUserController, :type => :controller do

  let(:user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      expect(response).to be_successful
    end

    it 'signs out existing users' do
      sign_in user
      get 'new'
      expect(controller).to_not be_signed_in
    end
  end

  describe "POST 'create'" do
    subject { post 'create', params: { user: { username: user.username, password: 'foopass' }}}

    it 'sets the admin user' do
      allow(controller.warden).to receive(:authenticate!).and_return(user)
      expect(subject).to be_redirect
      expect(user).to be_an_admin
    end
  end

end
