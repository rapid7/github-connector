class AddGithubOrganizationMemberships < ActiveRecord::Migration[4.2]
  def change
    create_table :github_organization_memberships do |t|
      t.references :github_user, index: true, null: false
      t.string :organization, null: false
      t.string :role
      t.string :state

      t.timestamps null: false
    end
  end
end
