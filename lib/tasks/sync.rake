desc "Synchronize LDAP and GitHub users"
task sync: ['sync:ldap', 'sync:github']

namespace :sync do
  desc "Synchronize Github users and teams"
  task github: :environment do
    puts "Synchronizing Github..."
    sync = GithubSynchronizer.new
    sync.run!
    sync.stats.each do |key, val|
      puts "  #{key}: #{val}"
    end
    unless sync.errors.empty?
      puts "  Errors:"
      sync.errors.each do |error|
        puts "    #{error}"
      end
    end
  end

  desc "Synchronize Active Directory users"
  task ldap: :environment do
    puts "Synchronizing Active Directory..."
    sync = LdapSynchronizer.new
    sync.run!
    sync.stats.each do |key, val|
      puts "  #{key}: #{val}"
    end
    unless sync.errors.empty?
      puts "  Errors:"
      sync.errors.each do |error|
        puts "    #{error}"
      end
    end
  end
end
