module GithubOauthConcern
  extend ActiveSupport::Concern

  protected

  def oauth_authenticity_token
    session[:_oauth_state] ||= SecureRandom.base64(32)
  end

  def oauth_client
    settings = Rails.application.settings
    @oauth_client ||= OAuth2::Client.new(settings.github_client_id, settings.github_client_secret,
      site: 'https://github.com/',
      authorize_url: '/login/oauth/authorize',
      token_url: '/login/oauth/access_token'
    )
  end

  def oauth_process_auth_code
    octokit = Octokit::Client.new(access_token: oauth_auth_code.token)
    ghuser = octokit.user

    github_user = GithubUser.find_or_initialize_by(id: ghuser.id)
    github_user.login = ghuser.login
    github_user.token = oauth_auth_code.token
    github_user.user = current_user
    github_user.sync!
    github_user
  end

  def oauth_scope
    'user:email,read:public_key,write:org'
  end

  def oauth_validate_authenticity_token
    if oauth_state != oauth_authenticity_token
      raise ActionController::InvalidAuthenticityToken
    end
  end

  private

  def oauth_auth_code
    @oauth_auth_code ||= oauth_client.auth_code.get_token(oauth_code)
  end
end
