class SettingsController < ApplicationController
  include SettingsMixin
  include GithubOauthConcern
  include GithubSettingsMixin
  before_filter :require_admin

  def edit
  end

  def update
    unless test_ldap_connection
      render :edit
      return
    end
    @settings.save

    if params[:connect_github]
      github_admin
    else
      flash.notice = "Settings saved successfully."
      redirect_to action: :edit
    end
  end
end
