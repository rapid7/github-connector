module GithubSettingsMixin
  extend ActiveSupport::Concern

  def github_admin
    redirect_to oauth_client.auth_code.authorize_url(
      state: oauth_authenticity_token,
      scope: "#{oauth_scope},admin:org,repo",
      redirect_uri: url_for(action: 'github_auth_code')
    )
  end

  def github_auth_code
    oauth_validate_authenticity_token
    @github_user = oauth_process_auth_code
    Rails.application.settings.github_admin_token = oauth_auth_code.token
    flash.notice = "GitHub admin token updated successfully."
    redirect_to action: 'edit'
  end

  private

  def oauth_code
    params[:code]
  end

  def oauth_state
    params[:state]
  end
end
