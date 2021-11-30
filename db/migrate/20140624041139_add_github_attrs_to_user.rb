class AddGithubAttrsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_github_token, :string
    add_column :users, :github_login, :string
  end
end
