module SettingsConcern
  def settings
    Rails.application.settings
      .load(settings_keys)
      .disconnect
      .all
  end
end
