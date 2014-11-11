class AddGithubAttrsToUser < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_github_token, :string
    add_column :users, :github_login, :string
  end
end
