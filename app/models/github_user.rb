class GithubUser < ActiveRecord::Base
  include Encryptable
  include FriendlyId
  friendly_id :login

  attr_accessor :github_admin

  attr_encryptor :token

  belongs_to :user
  has_many :emails, class_name: 'GithubEmail', dependent: :destroy
  has_many :org_memberships, class_name: 'GithubOrganizationMembership', dependent: :destroy
  has_and_belongs_to_many :teams, class_name: 'GithubTeam', join_table: :github_user_teams
  has_and_belongs_to_many :disabled_teams, class_name: 'GithubTeam', join_table: :github_user_disabled_teams

  validates :login, uniqueness: true

  scope :active, -> { where.not(state: :disabled) }
  scope :disabled, -> { where(state: :disabled) }
  scope :enabled, -> { where(state: :enabled) }
  scope :external, -> { where(state: :external) }
  scope :excluded, -> { where(state: :excluded) }
  scope :linked, -> { where.not(user_id: nil) }
  scope :unlinked, -> { where(user_id: nil) }

  # Each user can be in one of the following states:
  # * enabled - user meets all rules, and can be a member of any team
  # * external - user only meets external rules and can only be a member
  #   of external teams
  # * disabled - user fails one or more rules and should not be a member
  #   of our organizations
  # * excluded - user is excluded from rules matching
  # * unknown - user has not yet been tracked
  state_machine :state, initial: :unknown do
    event :enable do
      transition any - :enabled => :enabled
    end

    event :restrict do
      transition any - :external => :external, unless: :global_excluded_user?
    end

    event :disable do
      transition any - :disabled => :disabled, unless: :global_excluded_user?
    end

    event :exclude do
      transition any - :excluded => :excluded
    end

    before_transition any => :enabled, do: :do_enable

    before_transition any => :external, do: :do_restrict
    after_transition :enabled => :external do |user, transition|
      user.send(:do_notify_restricted, transition) if user.failing_rules.any? { |rule| rule.notify? }
    end

    before_transition any => :disabled, do: :do_disable
    after_transition [:enabled, :external] => :disabled do |user, transition|
      user.send(:do_notify_disabled, transition) if user.failing_rules.any? { |rule| rule.notify? }
    end
  end

  # Add the user to our managed organizations.  This performs the
  # following steps:
  #   1. Invites user to our organization
  #   2. Accepts invitation
  #   3. Verifies all rules pass
  #   4. Adds to default teams
  #
  # @return [Boolean] true if successful, false otherwise
  def add_to_organizations
    orgs = Rails.application.settings.github_orgs || []
    return true if orgs.empty?
    check_mfa_team = Rails.application.settings.github_check_mfa_team
    default_teams = Rails.application.settings.github_default_teams
    raise "Must set github_check_mfa_team setting!" unless check_mfa_team
    raise "Must set github_default_teams setting!" unless default_teams

    # Add user to our organizations
    added_orgs = []
    checked_mfa = false
    orgs.each do |org|
      unless github_admin.octokit.organization_member?(org, login)
        Rails.logger.info "Adding #{login} to organization #{org}."
        team = GithubTeam.find_by_full_slug("#{org}/#{check_mfa_team}")
        raise "Adding #{login} to organization #{org}." \
              "\nCannot find the team '#{check_mfa_team}' for #{org}" unless team

        # Generate the invitation
        github_admin.octokit.add_team_membership(team.id, login)

        # Accept the invitation
        octokit.update_organization_membership(org, {state: 'active'})

        # MFA status can only be verified once the user is a member of
        # our organization.  If we haven't checked mfa yet, check it now.
        if Rules::GithubMfa.enabled? && !checked_mfa
          self.mfa = github_admin.user_mfa?(login, org)
          save
          checked_mfa = true

          # No use continuing if we don't have MFA enabled.
          break unless mfa
        end

        added_orgs << org
      end
    end

    # Check mfa if disabled and not already checked
    if Rules::GithubMfa.enabled? && !checked_mfa && !mfa
      self.mfa = github_admin.user_mfa?(login)
      save
      checked_mfa = true
    end

    # Check for failing rules
    valid_user = failing_rules.empty?

    # Add to default teams
    if valid_user
      add_to_teams(default_teams)
    end

    # Remove from the temporary MFA check team
    orgs.each do |org|
      team = GithubTeam.find_by_full_slug("#{org}/#{check_mfa_team}")
      raise "Adding #{login} to organization #{org}." \
              "\nCannot find the team '#{check_mfa_team}' for #{org}" unless team
      github_admin.octokit.remove_team_member(team.id, login)
    end

    valid_user
  end

  # Adds the user to the given Github teams.
  #
  # @params teams [Array<GithubTeam>|Array<String>] list of {GithubTeam}s or
  # team slugs
  # @return [Array<GithubTeam>]
  def add_to_teams(*teams)
    # Remove teams we're already a member of
    teams = normalize_teams(*teams).reject do |team|
      self.teams.include?(team)
    end

    # Add the teams to Github
    teams.each do |team|
      Rails.logger.info "Adding #{login} to team #{team.full_slug}."
      github_admin.octokit.add_team_membership(team.id, login)
    end

    # Cache the membership in the database
    self.teams += teams

    teams
  end
  alias :add_to_team :add_to_teams

  # Adds the user to {disabled_teams}, if any, and clears the {disabled_teams}
  # list.  This is useful to add the user to his previous teams after re-enabling
  # the user.
  #
  # @return [Array<GithubTeam>] the teams the user was added to
  def add_back_disabled_teams
    return [] if disabled_teams.empty?
    add_to_teams(disabled_teams).tap do
      disabled_teams.clear
    end
  end

  def as_json(options={})
    options[:except] ||= []
    options[:except] += [:encrypted_token, :id, :user_id]
    json = super(options)
    unless options[:except].include?(:user)
      json['user'] = user.as_json(except: [:github_users])
    end
    unless options[:except].include?(:teams)
      json['teams'] = teams.map { |ghteam| ghteam.full_slug }
    end
    json
  end

  # Should the Github user be excluded from processing by global settings?
  #
  # @return [Boolean]
  # @see {GithubConnector::Settings#github_exclude_users}
  def global_excluded_user?
    exclude_users = Rails.application.settings.github_exclude_users
    exclude_users && exclude_users.include?(login)
  end

  # Returns a list of failing rules for this User.
  #
  # @return [Rules::Iterator]
  def failing_rules
    @failing_rules ||= rules.dup.failing
  end

  def github_admin
    @github_admin ||= GithubAdmin.new
  end

  # The GitHub API client
  #
  # @return [Octokit::Client]
  def octokit
    @octokit ||= Octokit::Client.new(access_token: token)
  end

  # The GitHub organizations this user is a member of.
  #
  # @return [Array]
  def organizations
    teams.map do |team|
      team.organization
    end.compact.uniq
  end

  def organization_admin?(org)
    membership = org_memberships.find { |m| m.organization == org }
    return false unless membership
    membership.admin?
  end
  alias :org_admin? :organization_admin?

  # Returns a list of passing rules for this User.
  #
  # @return [Rules::Iterator]
  def passing_rules
    @passing_rules ||= rules.dup.passing
  end

  # Remove this user from all organizations, including normally excluded teams.
  #
  # @return [Array<GithubTeam>] list of {GithubTeam}s the user was removed from
  def remove_from_organizations
    orgs = Rails.application.settings.github_orgs || []
    remove_teams = teams.to_a
    return [] if orgs.empty?

    Rails.logger.info "Removing #{login} from organizations #{orgs.join(', ')}.  Removing from teams: #{remove_teams.map {|team| team.full_slug}.join(', ')}."

    orgs.each do |org|
      github_admin.octokit.remove_organization_member(org, login)
    end
    teams.clear

    remove_teams
  end

  # Remove this user from all non-external teams.
  #
  # @return [Array<GithubTeam>] list of {GithubTeam}s the user was removed from
  def remove_from_internal_teams
    remove_teams = teams.reject { |team| team.external? }
    return [] if remove_teams.empty?

    Rails.logger.info "Removing #{login} from teams: #{remove_teams.map {|team| team.full_slug}.join(', ')}"
    remove_teams.each do |team|
      if github_admin.octokit.remove_team_member(team.id, login)
        teams.destroy(team)
      end
    end

    remove_teams
  end

  # Returns a list of rules required for external users.
  #
  # @return [Rules::Iterator]
  def external_rules
    @external_rules ||= rules.dup.external
  end

  # Returns a list of enabled rules for this User.  All rules must pass
  # in order to gain full access to GitHub.
  #
  # @return [Rules::Iterator]
  def rules
    @rules ||= Rules.for_github_user(self)
  end

  # Synchronizes {GithubUser} attributes from GitHub.  This sets the attributes
  # and saves the +GithubUser+.  If GitHub API errors are encountered, they are
  # recorded in `sync_error` and logged to the Rails logger.
  #
  # @return [Boolean] true if saved successfully.  NOTE: This method returns
  # true even if GitHub API errors occur, as long as the error is successfully
  # saved to the `sync_error` attribute.
  def sync
    unless token
      self.sync_error = 'notoken'
      return save
    end

    orgs = Rails.application.settings.github_orgs || []

    # Pull data from GitHub API
    begin
      ghuser = octokit.user
      ghemails = octokit.emails.map { |h| h[:email] }
      ghmemberships = octokit.organization_memberships.inject({}) do |memo, membership|
        if orgs.include?(membership[:organization][:login])
          memo[membership[:organization][:login]] = {
            state: membership[:state],
            role: membership[:role],
          }
        end
        memo
      end
    rescue Octokit::Error => e
      Rails.logger.error "Error syncing #{login} with GitHub: #{e}"
      self.sync_error = e.class.name.demodulize.underscore
      return save
    end

    # Save results
    transaction do
      # Force associations reload just in case
      emails(true)
      org_memberships(true)

      # Remove old email addresses
      removed = emails.select do |email|
        !ghemails.include?(email.address)
      end
      emails.destroy(removed)

      # Add new email addresses
      existing_emails = emails.map(&:address)
      (ghemails - existing_emails).each do |added|
        emails.build(address: added)
      end

      # Remove old memberships
      removed = org_memberships.select do |membership|
        !ghmemberships.include?(membership.organization)
      end
      org_memberships.destroy(removed)

      # Sync new memberships
      ghmemberships.each do |org, attrs|
        existing = org_memberships.find { |membership| membership.organization == org }
        if existing
          existing.state = attrs[:state]
          existing.role = attrs[:role]
          existing.save
        else
          org_memberships.build(organization: org, state: attrs[:state], role: attrs[:role])
        end
      end

      self.login = ghuser.login
      self.last_sync_at = Time.now
      self.sync_error = nil
      save
    end
  end

  # Synchronizes {GithubUser} attributes from GitHub.
  # An `ActiveRecord::RecordNotSaved` error is raised if the save
  # fails.
  #
  # @return [void]
  def sync!
    sync || raise(ActiveRecord::RecordNotSaved.new("Error saving GithubUser: #{errors.count > 0 ? errors.full_messages.join("; ") : sync_error}", self))
  end

  def sync_error=(val)
    self.sync_error_at = val ? Time.now : nil
    super
  end

  # Transitions to the correct state based on the {User#rules} and
  # the current attributes.
  #
  # @return [Symbol] the event that was executed, or nil if no
  #   transition occured
  def transition
    new_state = case
    when global_excluded_user?
      :excluded
    when rules.valid?
      :enabled
    when external_rules.valid? && teams.any? { |team| team.external? }
      :external
    else
      :disabled
    end
    return nil if state == new_state

    transition = state_transitions.find do |t|
      t.from_name == state.to_sym && t.to_name == new_state
    end
    return nil unless transition && transition.event
    event = transition.event
    return nil unless send("can_#{event}?")

    self.send(event)
    event.to_sym
  end

  # Does the user have a valid GitHub token?
  #
  # @return [Boolean]
  def valid_token?
    return false unless token
    begin
      # We use rate limit as its a fast and free way to
      # test the GitHub token.
      octokit.rate_limit
    rescue Octokit::ClientError
      return false
    end
    true
  end

  private

  # Normalizes a list of slugs, full sligs, or {GithubTeam}s into
  # a single array of {GithubTeam}s.
  #
  # @params teams [Array<GithubTeam>|Array<String>] list of {GithubTeam}s or
  # team slugs
  # @return [Array<GithubTeam>]
  def normalize_teams(*teams)
    teams.flatten.inject([]) do |new_teams, team|
      if team.is_a?(GithubTeam)
        new_teams << team
      elsif team.include?('/')
        new_teams << GithubTeam.find_by_full_slug(team)
      else
        # Unqualified slugs may exist in multiple organizations
        new_teams += GithubTeam.where(slug: team)
      end
      new_teams
    end.compact.uniq
  end

  # Removes the GithubUser's GitHub access.  Removes the user from all
  # GitHub organizations and teams.
  #
  # @param transition [StateMachine::Transition]
  # @return [void]
  def do_disable(transition)
    Rails.logger.info "Transitioning #{login} from #{transition.from} to #{transition.to} via #{transition.event} event.  Failing rules: #{failing_rules.map(&:name).join(', ')}."
    if Rails.application.settings.enforce_rules
      self.disabled_teams = remove_from_organizations
    end
  end

  # Restricts the GithubUser's GitHub access to external teams.
  #
  # @param transition [StateMachine::Transition]
  # @return [void]
  def do_restrict(transition)
    Rails.logger.info "Transitioning #{login} from #{transition.from} to #{transition.to} via #{transition.event} event.  Failing rules: #{failing_rules.map(&:name).join(', ')}."
    if Rails.application.settings.enforce_rules
      self.disabled_teams = remove_from_internal_teams
    end
  end

  # Sends an email to the User indicating that their GitHub access
  # has been revoked.
  #
  # @param transition [StateMachine::Transition]
  # @return [void]
  def do_notify_disabled(transition)
    if user && Rails.application.settings.enforce_rules
      UserMailer.access_revoked(user, self).deliver_later
    end
  end

  # Sends an email to the User indicating that their GitHub access
  # has been restricted to external teams.
  #
  # @param transition [StateMachine::Transition]
  # @return [void]
  def do_notify_restricted(transition)
    if user && Rails.application.settings.enforce_rules
      UserMailer.access_revoked(user, self).deliver_later
    end
  end

  # Grants the user GitHub access
  #
  # @param transition [StateMachine::Transition]
  # @return [void]
  def do_enable(transition)
    Rails.logger.info "Transitioning #{login} from #{transition.from} to #{transition.to} via #{transition.event} event.  Passing rules: #{passing_rules.map(&:name).join(', ')}."
    add_back_disabled_teams
  end

end
