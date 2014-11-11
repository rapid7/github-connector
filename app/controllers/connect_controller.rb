require 'oauth2'

class ConnectController < ApplicationController
  include GithubOauthConcern
  before_filter :load_connect_status, only: [:status]

  def index
    @connect_status = ConnectGithubUserStatus.new(
      step: :request
    )
  end

  def status
    render :index
  end

  def start
    redirect_to oauth_client.auth_code.authorize_url(
      state: oauth_authenticity_token,
      scope: oauth_scope,
      redirect_uri: oauth_redirect_uri
    )
  end

  def auth_code
    if params[:state] != oauth_authenticity_token
      raise ActionController::InvalidAuthenticityToken
    end

    connect_job_status = ConnectGithubUserStatus.create!(
      user: current_user,
      oauth_code: params[:code],
      status: :queued,
      step: :grant
    )
    ConnectGithubUserJob.perform_later(connect_job_status)
    redirect_to connect_status_path(connect_job_status)
  end

  protected

  def oauth_redirect_uri
    url_for action: 'auth_code'
  end

  private

  def load_connect_status
    @connect_status = ConnectGithubUserStatus.find(params[:id])

    if @connect_status.user_id != current_user.id
      render :status => :forbidden, :text => 'Forbidden'
      return false
    end

    true
  end
end
