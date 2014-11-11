module Rules
  # @return [Array<Class>] an array of enabled {Rules::Base} classes
  def self.enabled_rules
    @all_rules ||= begin
      Dir[File.join(File.dirname(__FILE__), 'rules', '*.rb')].map do |file|
        filename = File.basename(file, '.rb')
        next if filename == 'base'
        Rules.const_get(filename.classify, false) rescue nil
      end.compact
    end
    @all_rules.select { |rule| rule.enabled? }
  end

  # @param user [GithubUser]
  # @return [Rules::Iterator] an array of {Rules::Base}s for the given user
  def self.for_github_user(user)
    rules = enabled_rules.map { |klass| klass.new(user) }
    Iterator.new(rules)
  end

  ##
  # An `Enumerable` wrapper around rules.  It allows filtering
  # and provides summary methods.  Assign a `Proc` to
  # {Iterator#selectors} to filter rules.
  class Iterator
    include ::Enumerable

    # @return [Array<Rules::Base>] an array of rules
    attr_reader :rules

    # @return [Proc] callbacks to filter rules
    attr_accessor :selectors

    def initialize(rules)
      @rules = rules
      @selectors = []
    end

    def initialize_copy(other)
      super
      @selectors = other.selectors.dup
    end

    # Calls the given block once for each element in `self`, passing that
    # element as a parameter.  Elements are filtered by {#selectors} if
    # set.
    #
    # @yieldparam element [Rules:Base] a rule
    # @return [void]
    def each(&block)
      rules.each do |rule|
        next unless selectors.all? { |selector| selector.call(rule) }
        block.call(rule)
      end
    end

    # Returns `true` if `self` contains no elements
    # @return [Boolean]
    def empty?
      !any? { true }
    end

    # Includes only failing rules
    #
    # @return [Iterator] self
    def failing
      self.selectors << lambda { |rule| !rule.valid? }
      self
    end

    # Includes only rules required for external access
    #
    # @return [Iterator] self
    def external
      self.selectors << lambda { |rule| rule.required_for_external? }
      self
    end

    # Includes only passing rules
    #
    # @return [Iterator] self
    def passing
      self.selectors << lambda { |rule| rule.valid? }
      self
    end

    # Returns the result of all rules in `self`
    # @return [Boolean] `true` if all rules are valid, `false` otherwise
    def result
      all?(&:result)
    end

    # Returns `true` if all rules in `self` are valid
    # @return [Boolean]
    def valid?
      !!result
    end
  end
end
