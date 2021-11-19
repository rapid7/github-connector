class User < ActiveRecord::Base
  include FriendlyId
  friendly_id :username

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :rememberable, :trackable

  has_many :github_users

  validates :username, uniqueness: true

  scope :linked, -> { joins(:github_users) }
  scope :unlinked, -> { joins('LEFT OUTER JOIN github_users ON github_users.user_id = users.id').where(github_users: {id: nil}) }

  # UserAccountControl flags
  # @see http://support.microsoft.com/kb/305144
  module AccountControl
    SCRIPT = 0x0001
    ACCOUNT_DISABLED = 0x0002
    HOMEDIR_REQUIRED = 0x0008
    LOCKOUT = 0x0010
    PASSWD_NOTREQD = 0x0020
    PASSWD_CANT_CHANGE = 0x0040
    ENCRYPTED_TEXT_PWD_ALLOWED = 0x0080
    TEMP_DUPLICATE_ACCOUNT = 0x0100
    NORMAL_ACCOUNT = 0x0200
    INTERDOMAIN_TRUST_ACCOUNT = 0x0800
    WORKSTATION_TRUST_ACCOUNT = 0x1000
    SERVER_TRUST_ACCOUNT = 0x2000
    DONT_EXPIRE_PASSWORD = 0x10000
    MNS_LOGON_ACCOUNT = 0x20000
    SMARTCARD_REQUIRED = 0x40000
    TRUSTED_FOR_DELEGATION = 0x80000
    NOT_DELEGATED = 0x100000
    USE_DES_KEY_ONLY = 0x200000
    DONT_REQ_PREAUTH = 0x400000
    PASSWORD_EXPIRED = 0x800000
    TRUSTED_TO_AUTH_FOR_DELEGATION = 0x1000000
    PARTIAL_SECRETS_ACCOUNT = 0x04000000
  end

  # Callback from Devise.  This synchronizes the user data from
  # LDAP to our local database.
  #
  # @return [void]
  def after_ldap_authentication
    if ldap_entry
      sync_from_ldap!
    end
  end

  def as_json(options={})
    options[:except] ||= []
    options[:except] += [:id]
    options[:methods] ||= [:ldap_account_control_flags]
    json = super(options)
    unless options[:except].include?(:github_users)
      json['github_users'] = github_users.map { |ghuser| ghuser.login }
    end
    json
  end

  # Returns a list of Github email addresses
  #
  # @return [Array<String>]
  def github_emails
    github_users.inject([]) do |emails, github_user|
      emails += github_user.emails.map(&:address)
    end
  end

  def ldap_account_control_flags
    return [] unless ldap_account_control
    AccountControl.constants.inject([]) do |flags, const|
      if (AccountControl.const_get(const) & ldap_account_control) != 0
        flags << const.downcase
      end
      flags
    end
  end

  # Returns a single parameter from LDAP or nil.  Normally, Net::LDAP::Entry
  # returns an array of values or nil if the parameter doesn't exist.  This
  # returns the first value from the array, or nil if it doesn't exist.
  #
  # @param param [String] parameter to retrieve from LDAP
  # @return [Object] first value for the given parameter
  def ldap_get_single_param(param)
    value = ldap_get_param(param)
    if value.is_a?(Array)
      value = value.first
    end
    value
  end

  def ldap_sync_error=(val)
    self.ldap_sync_error_at = val ? Time.now : nil
    super
  end

  # Synchronizes {User} attributes from Active Directory and GitHub.
  #
  # @return [Boolean] true if saved successfully
  def sync
    sync_from_ldap & sync_from_github
  end

  # Synchronizes {User} attributes from Active Directory and GitHub.
  # An `ActiveRecord::RecordNotSaved` error is raised if the save
  # fails.
  #
  # @return [void]
  def sync!
    sync || raise(ActiveRecord::RecordNotSaved)
  end

  def sync_from_github
    github_users.inject(true) do |result, github_user|
      result & github_user.sync
    end
  end

  # Syncrhonizes {User} attributes from GitHub.  This sets the attributes
  # and saves the +User+.  A `ActiveRecord::RecordNotSaved` error is raised
  # if the save fails.
  #
  # @return [void]
  def sync_from_github!
    sync_from_github || raise(ActiveRecord::RecordNotSaved)
  end

  # Synchronizes {User} attributes from LDAP.  This sets the attributes
  # and saves the +User+.  If LDAP errors are encountered, they are
  # recorded in `ldap_sync_error` and logged to the Rails logger.
  #
  # @return [Boolean] true if saved successfully.  NOTE: This method returns
  # true even if LDAP errors occur, as long as the error is successfully
  # saved to the `ldap_sync_error` attribute.
  def sync_from_ldap
    begin
      self.name = ldap_get_single_param('name')
      self.email = ldap_get_single_param('mail')
      self.ldap_account_control = ldap_get_single_param('userAccountControl')
      self.last_ldap_sync = Time.now
      self.ldap_sync_error = nil
      self.department = ldap_get_single_param('department')
      save
    rescue Net::LDAP::Error, Net::LDAP::PDU::Error => e
      Rails.logger.error "Error syncing #{username} with Active Directory: #{e}"
      self.ldap_sync_error = e.message
      return save
    end
  end

  # Synchronizes {User} attributes from LDAP.  This sets the attributes
  # and saves the +User+.  An `ActiveRecord::RecordNotSaved` error is
  # raised if the save fails.
  #
  # @return [void]
  def sync_from_ldap!
    sync_from_ldap || raise(ActiveRecord::RecordNotSaved)
  end

  private

  class << self
    alias_method :find_for_ldap_authentication_without_normalize, :find_for_ldap_authentication
  end

  # Finds the User using the normalized ldap username.
  #
  # @param attributes [Hash] Devise attributes
  # @return User
  # @see normalize_ldap_username
  def self.find_for_ldap_authentication(attributes={})
    auth_key = self.authentication_keys.first
    return nil unless attributes[auth_key].present?

    auth_key_value = (self.case_insensitive_keys || []).include?(auth_key) ? attributes[auth_key].downcase : attributes[auth_key]
    auth_key_value = (self.strip_whitespace_keys || []).include?(auth_key) ? auth_key_value.strip : auth_key_value

    # Strip AD domain if given
    if auth_key_value.include?('\\')
      auth_key_value = auth_key_value.split('\\', 2)[1]
    end

    resource = where(auth_key => auth_key_value).first
    if resource.blank?
      # If we can't find the resource using the given username
      # try searching different attributes using ldap.
      auth_key_value = normalize_ldap_username(auth_key_value)
      return nil unless auth_key_value
    end

    attrs = attributes.dup
    attrs[auth_key] = auth_key_value
    find_for_ldap_authentication_without_normalize(attrs)
  end

  # Searches for the username in common username attributes
  # (sAMAccountName, userPrincipalName, mail) and if found returns
  # the normalized username attribute (sAMAccountName).
  #
  # @param username [String] the username to normalize
  # @return [String] normalized username
  def self.normalize_ldap_username(username)
    ldap = Devise::LDAP::Adapter.ldap_connect(username).ldap
    ldap_entry = nil
    %w(sAMAccountName mail userPrincipalName).find do |ldap_attr|
      filter = Net::LDAP::Filter.eq(ldap_attr.to_s, username)
      ldap_entry = ldap.search(:filter => filter)
      ldap_entry = ldap_entry.first if ldap_entry
      DeviseLdapAuthenticatable::Logger.send("LDAP search for #{ldap_attr}=#{username}: #{ldap_entry ? "found match" : "no matches"}")
      ldap_entry
    end
    return nil unless ldap_entry

    username = ldap_entry['sAMAccountName']
    username = username.first if username.is_a?(Enumerable)
    username
  end
end
