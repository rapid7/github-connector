class RefactorGithubTables < ActiveRecord::Migration
  def change
    rename_table :teams, :github_teams
    rename_table :user_teams, :github_user_teams
    create_table(:github_users) do |t|
      t.belongs_to :user, index: true
      t.string :login, null: false
      t.boolean :mfa
      t.string :encrypted_token
      t.datetime :last_sync_at
      t.string :sync_error
      t.datetime :sync_error_at
      t.timestamps
    end
    add_index :github_users, :login, unique: true

    create_table :github_emails do |t|
      t.references :github_user, index: true, null: false
      t.string :address
      t.timestamps
    end
    add_column :users, :email, :string

    rename_column :github_user_teams, :user_id, :github_user_id
    rename_column :github_user_teams, :team_id, :github_team_id

    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO github_users
            (user_id, login, mfa, encrypted_token, last_sync_at, sync_error, sync_error_at)
            (SELECT id, github_login, github_mfa, encrypted_github_token, last_github_sync, github_sync_error, github_sync_error_at
              FROM users
              WHERE github_login IS NOT NULL
            )
        SQL
        execute <<-SQL
          INSERT INTO github_emails
            (github_user_id, address, created_at, updated_at)
            (SELECT github_users.id, emails.address, emails.created_at, emails.updated_at
              FROM emails
                INNER JOIN users ON emails.user_id = users.id
                INNER JOIN github_users ON github_users.user_id = users.id
              WHERE emails.source = 'github')
        SQL
        execute <<-SQL
          UPDATE users AS u
            SET email = emails.address
            FROM users
              INNER JOIN emails ON users.id = emails.user_id
              WHERE emails.source = 'ldap'
        SQL
        execute <<-SQL
          UPDATE github_user_teams AS user_team
            SET github_user_id = github_users.id
            FROM github_user_teams
              INNER JOIN users ON github_user_teams.github_user_id = users.id
              INNER JOIN github_users ON users.id = github_users.user_id
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE users AS u
            SET github_login = github_users.login,
              github_mfa = github_users.mfa,
              encrypted_github_token = github_users.encrypted_token,
              last_github_sync = github_users.last_sync_at,
              github_sync_error = github_users.sync_error,
              github_sync_error_at = github_users.sync_error_at
            FROM users
              INNER JOIN github_users ON github_users.user_id = users.id
        SQL
        execute <<-SQL
          UPDATE github_user_teams AS user_team
            SET github_user_id = users.id
            FROM github_user_teams
              INNER JOIN github_users ON github_users.id = github_user_teams.github_user_id
              INNER JOIN users ON users.id = github_users.user_id
        SQL
        execute <<-SQL
          INSERT INTO emails
            (user_id, address, source, created_at, updated_at)
            (SELECT id, email, 'ldap', NOW(), NOW() FROM users)
        SQL
        execute <<-SQL
          INSERT INTO emails
            (user_id, address, source, created_at, updated_at)
            (SELECT github_users.user_id, github_emails.address, 'github', github_emails.created_at, github_emails.updated_at
              FROM github_emails
              INNER JOIN github_users ON github_emails.github_user_id = github_users.id)
        SQL
      end
    end

    remove_column :users, :github_login, :string
    remove_column :users, :github_mfa, :boolean
    remove_column :users, :encrypted_github_token, :string
    remove_column :users, :last_github_sync, :datetime
    remove_column :users, :github_sync_error, :string
    remove_column :users, :github_sync_error_at, :datetime

    revert do
      create_table :emails do |t|
        t.references :user, index: true
        t.string :address
        t.string :source
        t.timestamps
      end
      add_index :emails, :source
    end
  end
end
