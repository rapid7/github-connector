class AddConnectGithubUserStatuses < ActiveRecord::Migration[4.2]
  def change
    create_table(:connect_github_user_statuses) do |t|
      t.belongs_to :user
      t.belongs_to :github_user
      t.string :oauth_code
      t.string :status
      t.string :step
      t.text :error_message
      t.timestamps
    end
  end
end
