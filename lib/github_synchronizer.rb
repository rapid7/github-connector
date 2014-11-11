class GithubSynchronizer < BaseExecutor


  # A Github admin client.
  # @return [GithubAdmin]
  attr_accessor :github_admin

  # A hash of statistics from the most recent run.  Includes:
  #   * users_time - User sync execution time
  #   * teams_time - Team sync execution time
  #   * teams_added
  #   * teams_deleted
  #   * teams_synced
  #   * teams_errors
  #   * users_synced
  #   * users_errors
  #
  # @return [Hash]
  attr_reader :stats

  def initialize
    super()
    @stats = {}
  end

  # A Github admin client.
  #
  # @return [GithubAdmin]
  def github_admin
    @github_admin ||= GithubAdmin.new
  end

  # Synchronizes all GitHub users from our organizations.
  #
  # @return [Bolean]
  def sync_users
    start = Time.now
    stats[:users_added] = 0
    stats[:users_deleted] = 0
    stats[:users_synced] = 0
    stats[:user_errors] = 0
    threads = []

    org_users = github_admin.org_users.values

    destroyed = GithubUser.joins(
        GithubUser.arel_table.join(User.arel_table, Arel::Nodes::OuterJoin).
        on(GithubUser.arel_table[:user_id].eq(User.arel_table[:id])).
        join_sources
      ).where.not(id: org_users.map { |u| u[:id] }).
      where(User.arel_table[:id].eq(nil)).
      destroy_all
    stats[:users_deleted] = destroyed.count

    processed = []
    thread_for_each(org_users) do |org_user|
      begin
        synchronize do
          next if processed.include?(org_user[:login])
          processed << org_user[:login]
        end
        github_user = GithubUser.find_or_initialize_by(id: org_user[:id])
        is_new = github_user.new_record?
        github_user.login = org_user[:login]
        github_user.avatar_url = org_user[:avatar_url]
        github_user.html_url = org_user[:html_url]
        github_user.mfa = org_user[:mfa_enabled]
        github_user.last_sync_at = Time.now unless github_user.token
        github_user.save!
        # Sync with the user's token, if available
        github_user.sync! if github_user.token
        synchronize do
          if github_user.sync_error
            stats[:user_errors] += 1
            @errors << "Error synchronizing #{github_user.login}: #{github_user.sync_error}"
          elsif is_new
            stats[:users_added] += 1
          else
            stats[:users_synced] += 1
          end
        end
      rescue => e
        synchronize do
          stats[:user_errors] += 1
          @errors << e
          Rails.logger.error "Error processing user #{org_user[:login]}: #{e.message}"
        end
      end
    end

    stats[:user_errors] == 0
  rescue => e
    @errors << e
    Rails.logger.error "Error processing user: #{e.message}"
    false
  ensure
    stats[:users_time] = Time.now.to_f - start.to_f
  end

  # Synchronizes teams.
  #
  # @return [Boolean]
  def sync_teams
    start = Time.now
    stats[:teams_added] = 0
    stats[:teams_deleted] = 0
    stats[:teams_synced] = 0
    stats[:team_errors] = 0
    threads = []

    teams = github_admin.teams.values

    destroyed = GithubTeam.where.not(id: teams.map { |team_data| team_data[:id] }).destroy_all
    stats[:teams_deleted] = destroyed.count

    thread_for_each(teams) do |team_data|
      begin
        team = GithubTeam.find_or_initialize_by(id: team_data[:id])
        is_new = team.new_record?
        team.github_admin = github_admin
        team.sync!
        synchronize do
          if is_new
            stats[:teams_added] += 1
          else
            stats[:teams_synced] += 1
          end
        end
      rescue => e
        synchronize do
          stats[:team_errors] += 1
          @errors << e
          Rails.logger.error "Error processing team #{team_data[:organization]}/#{team_data[:slug]}: #{e.message}"
        end
      end
    end

    stats[:team_errors] == 0
  rescue => e
    stats[:team_errors] += 1
    @errors << e
    Rails.logger.error "Error synchronizing teams: #{e.message}"
    false
  ensure
    stats[:teams_time] = Time.now.to_f - start.to_f
  end

  # Synchronizes Github organizations with our local database.
  # Synchronization is run in threads according to {#thread_count}.
  #
  # @return [Boolean] `true` if synchronizer executed successfully, `false` otherwise
  def run!
    start = Time.now
    @errors = []
    @stats = {}

    Rails.application.settings.with_disconnected do |settings|
      settings.reload

      # Check rate limit
      rate_limit = github_admin.octokit.rate_limit
      unless rate_limit.remaining > 100
        @errors << StandardError.new("Not running because Github rate limit is too low: #{rate_limit.remaining} remaining.  Please try again after #{Time.now + rate_limit.resets_in}.")
        return false
      end

      # Synchronize Github user information
      sync_users

      # Synchronize team information
      sync_teams

      stats[:api_requests] = rate_limit.remaining - github_admin.octokit.rate_limit.remaining
      stats[:total_time] = Time.now.to_f - start.to_f
    end

    @errors.empty?
  end
end
