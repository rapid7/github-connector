class AddGithubTeams < ActiveRecord::Migration
  def change
    create_table(:teams) do |t|
      t.string :slug
      t.string :organization
      t.string :name
      t.timestamps
    end

    create_table :user_teams, id: false do |t|
      t.belongs_to :user
      t.belongs_to :team
    end
  end
end
