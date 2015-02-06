class AddPowerUserToUser < ActiveRecord::Migration
  def change
    add_column :users, :power_user, :boolean
  end
end
