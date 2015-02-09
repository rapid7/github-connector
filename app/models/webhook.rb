class Webhook
  def self.all(*)
    YAML.load(File.read(Rails.root.join('config', 'webhooks.yml').to_path))
  end
end
