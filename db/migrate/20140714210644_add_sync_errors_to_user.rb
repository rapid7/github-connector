class AddSyncErrorsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :github_sync_error, :string
    add_column :users, :github_sync_error_at, :datetime
    add_column :users, :ldap_sync_error, :string
    add_column :users, :ldap_sync_error_at, :datetime
  end
end
