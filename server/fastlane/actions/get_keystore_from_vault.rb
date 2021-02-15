
module Fastlane
  module Actions
    require 'openssl'
    require 'vault'
    require 'tmpdir'
    require 'pry-byebug'

    class GetKeystoreFromVaultAction < Action
      def self.run(params)
        Vault.address = params[:vault_addr]
        Vault.token = params[:vault_token]

        private_key, private_key_passphrase = private_key_data
        decrypter = OpenSSL::PKey::RSA.new(private_key, private_key_passphrase)

        keystore_name = params[:keystore_name]
        encoded_keystore_data, encrypted_keystore_password = keystore_data(keystore_name)
        keystore_password = decrypter.private_decrypt(encrypted_keystore_password)

        decoded_keystore_filepath = tmp_keystore_filepath

        File.open(decoded_keystore_filepath, 'wb') do |f|
          f.write(Base64.decode64(encoded_keystore_data))
        end

        at_exit do
          FileUtils.rm_rf(decoded_keystore_filepath)
        end

        return {
          keystore_path: decoded_keystore_filepath,
          keystore_password: keystore_password
        }
      end

      def self.tmp_keystore_filepath
          keystore_name = "#{SecureRandom.urlsafe_base64}.keystore-db"
          File.join(Dir.tmpdir, keystore_name)
      end

      def self.keystore_data(keystore_name)
        secret_path = "secret/data/custom-mobile-apps/keystores/#{keystore_name}"
        keystore_secret = Vault.logical.read(secret_path)
        encoded_keystore_data = keystore_secret.data.dig(:data, :keystore_encoded_data)
        encoded_encrypted_keystore_password  = keystore_secret.data.dig(:data, :encoded_encrypted_keystore_password)
        encrypted_keystore_password = Base64.decode64(encoded_encrypted_keystore_password)

        [encoded_keystore_data, encrypted_keystore_password]
      end

      def self.private_key_data
        secret_path = "secret/data/custom-mobile-apps/crypto"
        crypto_secret = Vault.logical.read(secret_path)

        encoded_private_key = crypto_secret.data.dig(:data, :encoded_private_key)
        passphrase = crypto_secret.data.dig(:data, :passphrase)

        private_key = Base64.decode64(encoded_private_key)
        [private_key, passphrase]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Gets a given keystore from Vault and unlocks it"
      end

      def self.details
        "Gets a given keystore and its encrypted password from Vault. Decrypts the encrypted password provides both to the callee"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :vault_addr,
            env_name: "VAULT_ADDR",
            description: "The address of the Vault server expressed as a URL and port, for example: https://127.0.0.1:8200/",
          ),
          FastlaneCore::ConfigItem.new(
            key: :vault_token,
            env_name: "VAULT_TOKEN",
            description: "Vault authentication token",
            is_string: false,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_name,
            description: "The name of the custom mobile apps keystore"
          )
        ]
      end


      def self.return_value
        "A hash containing a :keystore_path and a :keystore_password"
      end

      def self.authors
        ["lyndsey-ferguson/lyndseydf"]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
