require 'settings/definition'

# The +Settings+ classes and methods wrap the {Setting} database object
# allowing easy access to application settings.
module Settings
  ##
  # The settings class allows defining and interacting with settings via
  # the {Setting} model.  Settings are defined via the {setting} method.
  #
  # By default the settings are loaded from and saved to the database
  # immediately when getting and setting.  The {#disconnect} returns a
  # disconnected instance that does not automaticallying update the
  # database.  A disconnected object can be loaded and saved via {#load}
  # and {#save}.
  #
  # @example
  #     class MySettings
  #       setting :api_username
  #       setting :api_password, encrypt: true
  #       setting :api_ssl, type: boolean
  #       setting :api_port, type: integer
  #     end
  class Base
    include Encryptable

    # A list of {Settings::Definition}s.
    #
    # @return [Array<Settings::Definition>]
    def self.definitions
      @definitions ||= {}
    end

    # Creates a setting.
    #
    # @param key [Symbol]
    # @param opts [Hash] setting options
    # @option opts [Symbol] :type one of `:string`, `:integer`, `:float`,
    #   `:boolean`, `:datetime`
    # @option opts [Boolean] :encrypt should the value be encrypted in the database?
    #
    # @example Define the setting type
    #     setting :my_setting, type: integer
    # @example Encrypt the setting in the database
    #     setting :secure_setting, encrypt: true
    def self.setting(key, opts={})
      definition = Definition.new(key, opts)
      definitions[key.to_sym] = definition
      define_method("#{key}=") { |val| set(key, val) }
      define_method("#{key}") { get(key) }
      if definition.type == :boolean
        define_method("#{key}?") { !!send("#{key}") }
      end
    end

    def initialize
      @settings = {}
      @disconnected = false
      @dirty = Set.new
    end

    # Returns the {Settings::Definition} for the given setting
    #
    # @param key [Symbol] the setting name
    # @return [Settings::Definition]
    def definition(key)
      self.class.definitions[key.to_sym]
    end

    # Has the given key been modified?
    #
    # @param key [Symbol] the setting
    # @return [Boolean] true if the setting has been modified
    #   without saving, false otherwise
    def dirty?(key)
      @dirty.include?(key.to_sym)
    end

    # Return a new disconnected settings object.  Accessing settings will not
    # automatically query the database.  Setting values will not automatically
    # save to the database.  You can still manually call the {#load} and {#save}
    # methods.
    #
    # @return [Settings::Base] disconnected settings object
    def disconnect
      clone.tap { |c| c.disconnected = true }
    end

    # Is this instance disconnected?
    #
    # @return [Boolean]
    def disconnected?
      @disconnected
    end

    # Returns a hash with the given settings and values
    #
    # @param keys [Array<Symbol>] array of settings to include in the hash
    # @return [Hash]
    # @see {#to_h}
    def hash_for(keys)
      reload(keys) unless disconnected?
      @settings.inject({}) do |memo, (key, val)|
        if keys.include?(key.to_s) || keys.include?(key.to_sym)
          memo[key.to_sym] = val
        end
        memo
      end
    end

    # An array of setting names defined in this instance.
    #
    # @return [Array<Symbol>]
    def keys
      self.class.definitions.map do |key, definition|
        key
      end
    end

    # Load the given settings from the database.  If no keys are specified,
    # all defined settings will be loaded.
    #
    # @param keys [Array<Symbol>] array of setting names
    # @return [Settings::Base] self
    def load(keys=nil)
      load_keys(keys || self.keys)
      self
    end
    alias :reload :load

    # Saves settings that have been modified.
    #
    # @return [void]
    def save
      @dirty.each { |key| save_key(key) }
    end

    # Returns a hash of all setting name/value pairs.
    #
    # @return [Hash]
    def to_h
      hash_for(keys)
    end
    alias :all :to_h

    # Runs the given block with disconnected settings.  After the block
    # returns, the disconnected state will be returned to its original value.
    # Calls to `with_disconnected` may be nested.
    #
    # @yieldparam settings [Settings::Base] disconnected settings
    # @return [Object] the return value of the block
    def with_disconnected(&block)
      prev = self.disconnected?
      begin
        self.disconnected = true
        block.call(self)
      ensure
        self.disconnected = prev
      end
    end

    protected
    # Sets the disconnected state
    #
    # @param bool [Boolean]
    # @return [void]
    # @see {#disconnect}
    def disconnected=(bool)
      @disconnected = !!bool
    end

    private
    def get(key)
      key = key.to_sym
      load_key(key) unless disconnected?
      @settings[key]
    end

    def load_keys(keys)
      return unless keys
      keys = [keys] unless keys.is_a?(Enumerable)
      keys.each do |key|
        @settings.delete(key)
        @dirty.delete(key)
      end
      Setting.where(key: keys).each do |setting|
        key = setting.key.to_sym
        val = setting ? setting.value : nil
        val = decrypt(val) if definition(key).encrypt?
        val = definition(key).type_cast(val)
        @settings[key] = val
      end
    end
    alias :load_key :load_keys

    def set(key, val)
      key = key.to_sym
      val = definition(key).type_cast(val)

      unless val == @settings[key]
        @settings[key] = val
        @dirty << key
      end
      save_key(key) unless disconnected?
    end

    def save_key(key)
      key = key.to_sym
      setting = Setting.find_by_key(key)
      setting ||= Setting.new(key: key)

      val = @settings[key]
      val = definition(key).db_cast(val)
      val = encrypt(val) if definition(key).encrypt?
      setting.value = val
      setting.save!
      @dirty.delete(key)
    end
  end
end
