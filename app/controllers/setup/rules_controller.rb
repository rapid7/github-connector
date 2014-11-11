class Setup::RulesController < ApplicationController
  include SetupMixin
  include SettingsMixin

  def edit
    apply_defaults unless @settings.rule_max_sync_age
  end

  def update
    @settings.save

    Rails.application.settings.configured = true
    flash.notice = "Setup Wizard completed successfully.  You may verify settings below."

    redirect_to settings_url
  end


  private

  def default_settings
    {
      rule_max_sync_age: 86400,
      rule_email_regex: "@(#{default_domain.gsub('.', '\.')}|users\\.noreply\\.github\\.com)$",
      github_user_requirements: [
        '<strong>Must</strong> enable <a href="https://help.github.com/articles/about-two-factor-authentication">two factor authentication</a>',
        '<strong>Must</strong> only associate your company email address',
      ]
    }
  end
end
