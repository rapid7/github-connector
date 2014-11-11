class LdapSynchronizer < BaseExecutor

  # A hash of statistics from the most recent run.  Includes:
  #   * users_time - User sync execution time
  #   * users_synced
  #   * users_errors
  #
  # @return [Hash]
  attr_reader :stats

  # @return [Enumerable<User>] a list of users to synchronize
  attr_reader :users

  # @param users [Enumerable<User>] a list of users to synchronize
  def initialize(users=User.all)
    super()
    @stats = {}
    @users = users
  end

  # Synchronizes all Active Directory users.
  #
  # @return [Bolean]
  def sync_users
    start = Time.now
    stats[:users_synced] = 0
    stats[:user_errors] = 0
    threads = []

    thread_for_each(users) do |user|
      begin
        user.sync_from_ldap!
        synchronize do
          if user.ldap_sync_error
            stats[:user_errors] += 1
            @errors << "Error synchronizing #{user.username}: #{user.ldap_sync_error}"
          else
            stats[:users_synced] += 1
          end
        end
      rescue => e
        synchronize do
          stats[:user_errors] += 1
          @errors << e
          Rails.logger.error "Error processing user #{user.username}: #{e.message}"
        end
      end
    end

    stats[:user_errors] == 0
  rescue => e
    stats[:user_errors] += 1
    @errors << e
    Rails.logger.error "Error synchronizing users: #{e.message}"
    false
  ensure
    stats[:users_time] = Time.now.to_f - start.to_f
  end

  # Synchronizes Active Directory users with our local database.
  # Synchronization is run in threads according to {#thread_count}.
  #
  # @return [Boolean] `true` if synchronizer executed successfully, `false` otherwise.
  def run!
    @errors = []
    @stats = {}

    Rails.application.settings.with_disconnected do |settings|
      settings.reload

      sync_users
    end

    @errors.empty?
  end
end
