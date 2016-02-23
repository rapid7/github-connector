require 'rails_helper'

RSpec.describe "settings/edit.html.erb", type: :view do
  # We can't call this "settings" because ViewExampleGroup adds view helpers
  # to the spec -- the settings helper would take precedence over a let
  let(:test_settings) { GithubConnector::Settings.new.disconnect; }
  let(:section_partials) { SettingsController.new.send(:section_partials) }
  let(:user) { build(:user) }

  before do
    controller.extend(SettingsMixin)
    controller.instance_variable_set('@settings', test_settings)
    assign(:settings, test_settings)
    assign(:section_partials, section_partials)
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'replaces existing password with placeholder' do
    test_settings.ldap_admin_password = 'foopass'
    test_settings.save
    render
    expect(rendered).to_not include('foopass')
  end

  it 'does not replace new password' do
    test_settings.ldap_admin_password = 'foopass'
    render
    expect(rendered).to include('foopass')
  end

  it 'replaces existing GitHub token with placeholder' do
    test_settings.github_admin_token = 'footoken'
    test_settings.save
    render
    expect(rendered).to_not include('footoken')
  end

  it 'does not replace new GitHub token' do
    test_settings.github_admin_token = 'footoken'
    render
    expect(rendered).to include('footoken')
  end
end
