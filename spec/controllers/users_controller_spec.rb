require 'rails_helper'

RSpec.describe UsersController, :type => :controller do
  before do
    sign_in(user)
    configured
  end

  let(:user) { create(:admin_user, name: 'Admin User') }

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_successful
    end

    it 'loads users in order' do
      get 'index'
      create(:user, name: 'Aaron Sorts First')
      names = assigns(:users).map { |user| user.name }
      expect(names).to eq(['Aaron Sorts First', 'Admin User'])
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      get 'show', params: { id: user.username }
      expect(response).to be_successful
    end

    context 'with admin user' do
      it 'shows other users' do
        create(:user, username: 'otheruser', name: 'Other User')
        get 'show', params: { id: 'otheruser' }
        expect(response).to be_successful
        expect(assigns(:user).username).to eq('otheruser')
      end
    end

    context 'with non-admin user' do
      let(:user) { create(:user, name: 'Regular User') }

      it 'shows own user' do
        get 'show', params: { id: user.username }
        expect(response).to be_successful
      end

      it 'does not show other users' do
        create(:user, username: 'otheruser', name: 'Other User')
        get 'show', params: { id: 'otheruser' }
        expect(response).to be_forbidden
      end
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', params: { id: user.username }
      expect(response).to be_successful
    end
  end

  describe "PATCH 'edit'" do
    it "redirects after save" do
      patch 'update', params: { id: user.username, user: { admin: 0 } }
      expect(response).to be_redirect
    end
  end
end
