namespace :github do

  task sync: 'sync:github'

  desc "Transitions Github users based on rules and current attributes"
  task transition_users: %w(environment sync:ldap sync:github) do

    # Make sure the majority of users have recently synced ldap and github
    min_sync_time = Time.now - [Rails.application.settings.rule_max_sync_age, 120].max + 120.seconds

    total_ldap_count = User.count
    synced_ldap_count = User.where('last_ldap_sync > ?', min_sync_time).count
    if synced_ldap_count < [total_ldap_count / 4, 1].max
      puts "Fewer than 25% of LDAP users (#{synced_ldap_count} of #{total_ldap_count}) meet minimum sync time.  Skipping transition."
      exit 1
    end

    total_github_count = GithubUser.active.count
    synced_github_count = GithubUser.active.where('last_sync_at > ?', min_sync_time).count
    if synced_github_count < [total_github_count / 4, 1].max
      puts "Fewer than 25% of GitHub users (#{synced_github_count} of #{total_github_count}) meet minimum sync time.  Skipping transition."
      exit 2
    end

    puts "Checking for users to disable..."
    executor = TransitionGithubUsers.new
    executor.run!

    disabled_users = executor.transitions.select { |u| u.disabled? }
    external_users = executor.transitions.select { |u| u.external? }

    executor.stats.each do |key, val|
      puts "  #{key}: #{val}"
    end

    if disabled_users.empty? && external_users.empty?
      puts "  No users to disable."
    end
    unless disabled_users.empty?
      puts "  Disabled Github users: #{disabled_users.map { |u| u.login }.join(', ')}"
    end
    unless external_users.empty?
      puts "  External Github users: #{external_users.map { |u| u.login }.join(', ')}"
    end

    unless executor.errors.empty?
      puts "  Errors:"
      executor.errors.each do |error|
        puts "    #{error}"
      end
    end
  end
end
