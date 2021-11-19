class ConvertSettingsValueToText < ActiveRecord::Migration[4.2]
  def change
    change_column :settings, :value, :text
  end
end
