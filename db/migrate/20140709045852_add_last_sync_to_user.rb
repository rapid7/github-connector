class AddLastSyncToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_ldap_sync, :datetime
    add_column :users, :last_github_sync, :datetime
  end
end
