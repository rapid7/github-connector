require 'rails_helper'

RSpec.describe "layouts/application", type: :view do
  before do
    Rails.application.settings.configured = true
    assign(:navbar, GithubConnector::Navbar.new)
  end

  context 'without user' do
    it 'does not display login items' do
      render
      expect(rendered).to_not include('Logout')
    end
  end

  context 'with user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'displays login items' do
      render
      expect(rendered).to include('Logout')
    end

    it 'does not display admin navigation' do
      render
      expect(rendered).to_not include('Settings')
    end
  end

  context 'with admin user' do
    let(:user) { create(:admin_user) }

    before do
      sign_in(user)
    end

    it 'displays admin navigation' do
      render
      expect(rendered).to include('Settings')
    end
  end
end
