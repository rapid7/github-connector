class AddSyncErrorsToUser < ActiveRecord::Migration
  def change
    add_column :users, :github_sync_error, :string
    add_column :users, :github_sync_error_at, :datetime
    add_column :users, :ldap_sync_error, :string
    add_column :users, :ldap_sync_error_at, :datetime
  end
end
