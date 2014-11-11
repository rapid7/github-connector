module GithubConnector
  class Helpers
    class << self
      include Opscode::OpenSSL::Password

      # Loads the given data bag.  The databag can be encrypted or unencrypted.
      def load_data_bag(data_bag, name)
        raw_hash = Chef::DataBagItem.load(data_bag, name)
        encrypted = raw_hash.detect do |key, value|
          if value.is_a?(Hash)
            value.has_key?("encrypted_data")
          end
        end
        if encrypted
          secret = Chef::EncryptedDataBagItem.load_secret
          Chef::EncryptedDataBagItem.new(raw_hash, secret)
        else
          raw_hash
        end
      end

      def database_password(node)
        secret('database_password', secure_password, node)
      end

      def database_key(node)
        secret('database_key', SecureRandom.hex(64), node)
      end

      def secret_key_base(node)
        secret('secret_key_base', SecureRandom.hex(64), node)
      end

      def secret(key, default, node)
        data_bag = GithubConnector::Helpers.load_data_bag(
          node['github_connector']['secrets_databag'],
          node['github_connector']['secrets_databag_item']
        ) rescue nil

        if data_bag && data_bag[key]
          return data_bag[key]
        end

        unless Chef::Config[:solo]
          node.set_unless['github_connector']['secrets'][key] = default
          node.save
        end

        raise "Must set github_connector.secrets.#{key}!" unless node['github_connector']['secrets'][key]

        node['github_connector']['secrets'][key]
      end
    end
  end
end
