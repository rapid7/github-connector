class Setup::CompanyController < ApplicationController
  include SetupMixin
  include SettingsMixin

  def edit
    apply_defaults unless @settings.company
  end

  def update
    @settings.save

    redirect_to setup_ldap_url
  end

  private

  def default_settings
    {
    }
  end
end
