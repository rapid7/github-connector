class GithubAdmin

  def initialize
    @semaphore = Mutex.new
  end

  # Returns a hash of GitHub user hashes belonging to one or more of
  # our organizations.  The returned hash is keyed by the GitHub login.
  # Two extra keys are added to each user hash:
  #   * mfa_enabled - true if 2FA is enabled, false otherwise
  #   * orgs - array of our organizations the user belongs to
  #
  # @return [Hash] list of users keyed by user login
  # @see GithubConnector::Settings#github_orgs
  def org_users
    synchronize { return @org_users if @org_users }

    users = {}
    orgs = settings.github_orgs || []
    orgs.each do |org|
      octokit.organization_members(org).each do |user|
        if users.has_key?(user.login)
          users[user.login][:orgs] << org
        else
          users[user.login] = user.to_h
          users[user.login][:mfa_enabled] = true
          users[user.login][:orgs] = [org]
        end
      end
    end
    orgs.each do |org|
      octokit.organization_members(org, filter: '2fa_disabled').each do |user|
        users[user.login][:mfa_enabled] = false
      end
    end

    synchronize { @org_users = users }
  end

  # The GitHub API client
  #
  # @return [Octokit::Client]
  def octokit
    @octokit ||= Octokit::Client.new(access_token: settings.github_admin_token, auto_paginate: true)
  end

  # Application settings
  #
  # @return [GithubConnector::Settings]
  def settings
    Rails.application.settings
  end

  # Returns an array of members of the given GitHub team
  #
  # @param [Hash, Integer, String] a team hash (from {#teams}), a team ID, or
  #   a team org/slug
  # @return [Hash] list of members keyed by user login
  def team_members(team_id)
    team_id = team_id_for(team_id)

    synchronize do
      @team_members ||= {}
      return @team_members[team_id] if @team_members.has_key?(team_id)
    end

    members = {}
    octokit.team_members(team_id).each do |member|
      members[member.login] = member.to_h
    end

    synchronize { @team_members[team_id] = members }
  end

  def team(team_id)
    team_id = team_id_for(team_id)

    synchronize do
      if @teams && @teams.has_key?(team_id)
        return @teams[team_id]
      end
    end

    team = octokit.team(team_id)
    team = team.to_h
    team[:organization] = team[:organization][:login] unless team[:organization].is_a?(String)
    team
  end

  # Returns an array of GitHub teams
  #
  # @return [Hash] list of teams keyed by ID
  # @see GithubConnector::Settings#github_orgs
  def teams
    synchronize { return @teams if @teams }

    teams = {}
    orgs = settings.github_orgs || []
    orgs.each do |org|
      octokit.organization_teams(org).each do |team|
        team = team.to_h
        team[:organization] = org
        teams[team[:id]] = team
      end
    end

    synchronize { @teams = teams }
  end

  # Converts the given parameter into a team ID
  #
  # @param [Hash, String, Fixnum] a team ID, hash, or slug
  # @return [Fixnum]
  def team_id_for(team_param)
    team_id = team_param
    if team_param.is_a?(Hash)
      team_id = team_param[:id]
    elsif team_param.is_a?(String) && team_param.to_i.to_s != team_param
      team_data = teams.values.find do |t|
        team_param == t[:slug] || team_param == "#{t[:organization]}/#{t[:slug]}"
      end
      team_id = team_data ? team_data[:id] : nil
    end
    team_id
  end

  # Checks if the user has MFA enabled.
  # NOTE: The user must already be a member of the organization.  This does not
  # check this.
  #
  # @param login [String] a GitHub user login
  # @param org [String] a GitHub organization to check
  # @return [Boolean] true if the user has MFA enabled, false otherwise
  def user_mfa?(login, org=nil)
    synchronize {
      if @org_users && @org_users[login]
        return @org_users[login][:mfa_enabled]
      end
    }

    unless org
      org = settings.github_orgs.find do |org|
        octokit.organization_member?(org, login)
      end
    end
    return nil unless org

    !octokit.organization_members(org, filter: '2fa_disabled').any? do |user|
      user.login == login
    end
  end

  private

  # Obtains a lock, runs the block, and releases the lock when the block completes.
  #
  # @see `Mutex#synchronize`
  def synchronize(&block)
    @semaphore.synchronize(&block)
  end
end
