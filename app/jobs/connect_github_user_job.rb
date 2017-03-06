class ConnectGithubUserJob < ActiveJob::Base
  include GithubOauthConcern
  queue_as :default

  def perform(connect_status)
    @connect_status = connect_status

    @connect_status.update_attributes!(
      status: :running,
      step: :grant
    )

    # Process the user's token
    begin
      @github_user = oauth_process_auth_code
    rescue OAuth2::Error => e
      Rails.logger.warn "Cannot establish OAuth token: #{e.message}"
      @connect_status.update_attributes!(
        status: :error,
        error_message: e.description
      )
      return
    end

    @connect_status.update_attributes!(
      step: :add,
      github_user: @github_user
    )

    # Add to organizations
    unless @github_user.add_to_organizations
      @connect_status.update_attributes!(
        status: :error
      )
      return
    end

    # Enable user
    @github_user.enable if @github_user.can_enable?

    # Mark complete
    @connect_status.update_attributes!(
      status: :complete,
      step: :teams
    )

  rescue => e
    Rails.logger.error "Error running ConnectGithubUserJob: #{e}\n\t#{e.backtrace.join("\n\t")}"
    @connect_status.update_attributes!(
      status: :error,
      error_message: e.message
    )
  end

  private

  def current_user
    @connect_status.user
  end

  def oauth_code
    @connect_status.oauth_code
  end
end
