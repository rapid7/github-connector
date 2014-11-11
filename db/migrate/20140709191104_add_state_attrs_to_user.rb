class AddStateAttrsToUser < ActiveRecord::Migration
  def change
    add_column :users, :state, :string, null: false, default: :unknown
    add_column :users, :ldap_account_control, :integer
    add_column :users, :github_mfa, :boolean
  end
end
