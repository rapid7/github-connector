# Updates every {GithubUser}'s state based on existing attributes.
# You should normally run the {GithubSynchronizer} and {LdapSynchronizer}
# before running this executor.
#
# Users that meet the current ruleset will be enabled.  Those that do not
# meet the current rule set will be disabled.
class TransitionGithubUsers < BaseExecutor

  # A list of users to check and transition
  # @return [Enumerable<GithubUser>]
  attr_reader :github_users

  # A hash of statistics from the most recent run.  Includes:
  #   * users_transitioned
  #   * users_removed
  #   * users_restricted
  #   * transition_errors
  #   * transition_time
  #   * enforce_errors
  #   * remove_time
  #
  # @return [Hash]
  attr_reader :stats

  # The users that were transitioned as a result of this executor.
  # @return [Array<GithubUser>]
  attr_reader :transitions

  # The users that were removed from teams as a result of this executor.
  # This may include previously disabled users that have been added to
  # teams (via the Github UI) after the user was disabled.
  # @return [Array<GithubUser>]
  attr_reader :removed_github_users

  # The users that were restricted to external teams as a result of this
  # executor.  This may include previous restricted users that have been
  # added to internal teams (via the Github UI) after the user was
  # restricted.
  # @return [Array<GithubUser>]
  attr_reader :restricted_github_users

  # @param users [Enumerable<GithubUser>] a list of users to check
  def initialize(github_users=GithubUser.all)
    super()
    @github_users = github_users
    @transitions = []
    @removed_github_users = []
    @restricted_github_users = []
    @stats = {}
  end

  # Checks GithubUsers and disables those with failing rules.
  #
  # @return [Boolean] `true` if completed successfully
  def transition_users
    start = Time.now
    stats[:users_transitioned] = 0
    stats[:users_removed] ||= 0
    stats[:users_restricted] ||= 0
    stats[:transition_errors] = 0

    if github_users.is_a?(ActiveRecord::Relation)
      github_users.reload
    end

    thread_for_each(github_users) do |github_user|
      begin
        github_user.github_admin = github_admin
        if github_user.transition
          synchronize do
            stats[:users_transitioned] += 1
            stats[:users_removed] += 1 if github_user.disabled?
            stats[:users_restricted] += 1 if github_user.external?
            @transitions << github_user
            @removed_github_users << github_user if github_user.disabled?
            @restricted_github_users << github_user if github_user.external?
          end
        end
      rescue => e
        synchronize do
          stats[:transition_errors] += 1
          @errors << e
          Rails.logger.error "Error processing user #{github_user.login}: #{e}"
        end
      end
    end

    stats[:transition_errors] == 0
  rescue => e
    @errors << e
    stats[:transition_errors] += 1
    Rails.logger.error "Error checking and transitioning users: #{e.message}"
    false
  ensure
    stats[:transition_time] = Time.now.to_f - start.to_f
  end

  # A Github admin client.
  #
  # @return [GithubAdmin]
  def github_admin
    @github_admin ||= GithubAdmin.new
  end

  # Removes GitHub users in disabled state and ensures external users
  # only belong to external teams.
  #
  # @return [Boolean] `true` if completed successfully
  def enforce_state
    start = Time.now

    unless settings.enforce_rules
      Rails.logger.info "Skipping state enforcement because settings.enforce_rules is false"
      return false
    end

    stats[:users_removed] ||= 0
    stats[:users_restricted] ||= 0
    stats[:enforce_errors] = 0

    disabled_users = GithubUser.disabled
    thread_for_each(disabled_users) do |github_user|
      begin
        github_user.github_admin = github_admin
        teams = github_user.remove_from_organizations
        if teams && !teams.empty?
          github_user.disabled_teams = teams
        end
        synchronize do
          if teams && !teams.empty?
            stats[:users_removed] += 1
            @removed_github_users << github_user
          end
        end
      rescue => e
        synchronize do
          stats[:enforce_errors] += 1
          @errors << e
          Rails.logger.error "Error processing disabled user #{github_user.login}: #{e}"
        end
      end
    end

    external_users = GithubUser.external
    thread_for_each(external_users) do |github_user|
      begin
        github_user.github_admin = github_admin
        teams = github_user.remove_from_internal_teams
        if teams && !teams.empty?
          github_user.disabled_teams = teams
        end
        synchronize do
          if teams && !teams.empty?
            stats[:users_restricted] += 1
            @restricted_github_users << github_user
          end
        end
      rescue => e
        synchronize do
          stats[:enforce_errors] += 1
          @errors << e
          Rails.logger.error "Error processing external user #{github_user.login}: #{e}"
        end
      end
    end

    stats[:enforce_errors] == 0
  rescue => e
    stats[:enforce_errors] += 1
    @errors << e
    Rails.logger.error "Error removing disabled users: #{e.message}"
    false
  ensure
    stats[:remove_time] = Time.now.to_f - start.to_f
  end

  # Checks users and disables those that do not meet the acceptance
  # criteria.  Checks are run in threads according to {#thread_count}.
  #
  # @return [Boolean] `true` if executor executed successfully, `false` otherwise
  def run!
    start = Time.now
    @errors = []
    @transitions = []
    @removed_github_users = []
    @restricted_github_users = []

    # Attempt to workaround an auto-loading threading issue that causes
    # "Circular dependency detected while autoloading constant Rules".
    Rules.enabled_rules

    settings.with_disconnected do |settings|
      settings.reload

      transition_users
      enforce_state

      stats[:total_time] = Time.now.to_f - start.to_f
    end

    @errors.empty?
  end

  def settings
    Rails.application.settings
  end
end
