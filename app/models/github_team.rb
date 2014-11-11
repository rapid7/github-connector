class GithubTeam < ActiveRecord::Base
  has_and_belongs_to_many :github_users, join_table: :github_user_teams

  attr_accessor :github_admin

  # Finds a GithubTeam using a "full" slug.  A full slug
  # is the organization and team slug combined with a slash, for example:
  #   org1/myteam
  #
  # @param full_slug [String] an organization and team slug separated with a slash
  # @return [GithubTeam]
  def self.find_by_full_slug(full_slug)
    (org, slug) = full_slug.split('/', 2)
    where(organization: org, slug: slug).first
  end

  # Does this team allow external users?
  #
  # @return [Boolean]
  # @see {GithubConnector::Settings#github_external_users}
  def external?
    external_teams = Rails.application.settings.github_external_teams
    external_teams && (external_teams.include?(slug) || external_teams.include?(full_slug))
  end

  # Returns the "full" slug for this team.  A full slug
  # is the organization and team slug combined with a slash, for example:
  #   org1/myteam
  #
  # @return [String] an organization and team slug separated with a slash
  def full_slug
    "#{organization}/#{slug}"
  end

  def github_admin
    @github_admin ||= GithubAdmin.new
  end

  # Synchronizes {GithubTeam} attributes and members from Github.
  #
  # @return [Boolean] true if saved successfully.  NOTE: This method returns
  # true even if GitHub API errors occur, as long as the error is successfully
  # saved to the `sync_error` attribute.
  def sync
    # TODO: Handle errors
    sync_github_team & sync_github_members
  end

  # Synchronizes {GithubTeam} attributes and members from GitHub.
  # An `ActiveRecord::RecordNotSaved` error is raised if the save
  # fails.
  #
  # @return [void]
  def sync!
    sync || raise(ActiveRecord::RecordNotSaved)
  end

  protected

  def sync_github_team
    data = github_admin.team(id)
    self.id = data[:id]
    self.name = data[:name]
    self.organization = data[:organization]
    self.slug = data[:slug]
    if changed?
      save
    else
      true
    end
  end

  def sync_github_members
    members = github_admin.team_members(id)
    added_members = []
    removed_users = []

    github_users.each do |user|
      next if members.has_key?(user.login)
      # TODO: Don't remove disabled users???
      removed_users << user
    end
    github_users.delete(*removed_users) unless removed_users.empty?

    members.each do |login, member|
      next if github_users.any? { |user| user.login == login }
      added_members << login
    end
    github_users << GithubUser.where(login: added_members) unless added_members.empty?

    true
  end
end
