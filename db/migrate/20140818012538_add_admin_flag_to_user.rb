class AddAdminFlagToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :admin, :bool

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET admin='t'
            WHERE users.id IN (SELECT id FROM users ORDER BY created_at LIMIT 1)
        SQL
      end
    end
  end
end
