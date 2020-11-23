#!/usr/bin/env ruby

require_relative 'update_github_secret_value'

while true do
  secret = Vault.approle.create_secret_id("custom-mobile-apps-signer")
  update_secret_value('VAULT_CODESIGNING_SECRET_ID', secret.data[:secret_id])
  puts "Updated VAULT_CODESIGNING_SECRET_ID"
  STDOUT.flush
  sleep 2700
end