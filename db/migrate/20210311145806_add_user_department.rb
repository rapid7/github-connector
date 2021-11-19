class AddUserDepartment < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :department, :string
  end
end