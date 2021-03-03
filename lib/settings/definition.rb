require 'yaml'

module Settings
  ##
  # Defines a setting used in {Settings::Base}.
  class Definition
    # The setting name
    # @return [Symbol]
    attr_accessor :key

    # The setting type
    # @return [Symbol] one of `:string`, `:integer`, `:float`, `:boolean`, `:datetime`, `:array`, `:hash`
    attr_accessor :type

    # Whether the value should be encrypted in the database
    # @return [Boolean] true if the value should be encrypted, false otherwise
    attr_accessor :encrypt

    def initialize(key, opts)
      self.key = key.to_sym
      self.type = :string
      self.encrypt = false
      opts.each do |opt, val|
        send("#{opt}=", val) if respond_to?("#{opt}=")
      end
    end

    # Casts the given value for persistence in the database.
    #
    # @param [Object] val
    # @return [String] a string for persisting in the database
    def db_cast(val)
      return nil if val.nil?

      val = case type
        when :boolean then val ? 'true' : 'false'
        when :array, :hash then val ? val.to_json : nil
        else val.to_s
      end

      val
    end

    # Should the setting be encrypted when persisting?
    # @return [Boolean] true if the value should be encrypted, false otherwise
    def encrypt?
      !!@encrypt
    end

    # Checks if string is valid yaml before trying to load a yaml string
    #
    # @param [String] yaml
    # @return [Boolean] parsed yaml if string is valid yaml
    def valid_yaml_string?(yaml)
      !!YAML.load(yaml)
      return true
    rescue Exception => e
      STDERR.puts e.message
      return false
    end

    # Casts the given value according to the `type` setting option.
    #
    # @param [Object] val
    # @return [Object] the value, cast according to the `type` option
    def type_cast(val)
      return nil if val.nil?

      case type
        when :integer then val.to_i rescue val ? 1 : 0
        when :float then val.to_f
        when :boolean then val.to_s =~ /^(t|1|y)/i ? true : false
        when :datetime then DateTime.parse(val.to_s)
        when :array then val.is_a?(Array) ? val : JSON.parse(val)
        when :hash then val.is_a?(Hash) ? val : JSON.parse(val)
        when :yaml then val.is_a?(Hash) ? val : ( valid_yaml_string?(val) ? YAML.load(val) : eval(val) )
        else val
      end
    end
  end
end
