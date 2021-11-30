class SettingsController < ApplicationController
  include SettingsMixin
  include GithubOauthConcern
  include GithubSettingsMixin
  before_action :require_admin
  before_action :set_section_partials

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

  def section_partials
    {
      'Active Directory' => 'active_directory',
      'GitHub' => 'github',
      'Rules' => 'rules',
      'Email' => 'email',
    }
  end
  private :section_partials

  def set_section_partials
    @section_partials = section_partials
  end
  private :set_section_partials
end
