class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.references :user, index: true
      t.string :address
      t.string :source

      t.timestamps
    end
    add_index :emails, :source

    reversible do |dir|
      dir.up do
        execute "INSERT INTO emails (user_id, address, source, created_at, updated_at) SELECT id, email, 'ldap', NOW(), NOW() FROM users WHERE email IS NOT NULL"
        remove_column :users, :email
      end
      dir.down do
        add_column :users, :email, :string
        execute "UPDATE users AS u SET email=emails.address, updated_at=NOW() FROM users INNER JOIN emails ON users.id=emails.user_id"
      end
    end
  end
end
