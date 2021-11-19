module Encryptable
  extend ActiveSupport::Concern

  # The encrypted database salt environment variable.
  ENCRYPTED_DATABASE_SALT = 'encryptable.encrypted_database_salt'.freeze

  module ClassMethods
    def attr_encryptor(attr)
      field = "encrypted_#{attr}"
      define_method("#{attr}=") { |val|
        unless val == self.send("#{attr}")
          self.send("#{field}=", encrypt(val))
        end
      }
      define_method("#{attr}") { decrypt(self.send(field)) }
    end

    def crypt
      @crypt ||= begin
        salt = ENV[ENCRYPTED_DATABASE_SALT] || ''
        key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secrets.database_key, iterations: 2000)
        key = key_generator.generate_key(salt, 32)
        ActiveSupport::MessageEncryptor.new(key)
      end
    end
  end

  def encrypt(data)
    return nil if data.nil?
    self.class.crypt.encrypt_and_sign(data)
  end

  def decrypt(data)
    return nil if data.nil?
    self.class.crypt.decrypt_and_verify(data)
  end
end
