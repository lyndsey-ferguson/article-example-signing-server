#!/usr/bin/env ruby

require 'vault'
require_relative 'update_dot_env'

while true do
  secret = Vault.approle.create_secret_id("custom-mobile-apps-signer")
  update_dot_env_value('VAULT_CODESIGNING_SECRET_ID', secret.data[:secret_id])
  puts "Updated VAULT_CODESIGNING_SECRET_ID"
  STDOUT.flush
  sleep 2700
end