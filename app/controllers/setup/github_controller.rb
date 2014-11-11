class Setup::GithubController < ApplicationController
  include SetupMixin
  include SettingsMixin
  include GithubOauthConcern
  include GithubSettingsMixin

  def edit
    apply_defaults unless @settings.github_orgs
  end

  def update
    @settings.save

    if params[:connect_github]
      github_admin
    else
      redirect_to setup_email_url
    end
  end

  private

  def default_settings
    s = {
      github_check_mfa_team: 'github-connector-2fa-check',
    }
    unless Rails.application.settings.company.blank?
      s[:github_orgs] = [Rails.application.settings.company.downcase.gsub(' ', '-')]
      s[:github_default_teams] = ["#{Rails.application.settings.company.downcase.gsub(' ', '-')}-employees"]
    end

    s
  end
end
