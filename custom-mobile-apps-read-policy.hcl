path "secret/data/custom-mobile-apps/keychains/*" {
  capabilities = ["read"]
}

path "secret/data/custom-mobile-apps/apns_keys/*" {
  capabilities = ["read"]
}

path "secret/data/custom-mobile-apps/keystores/*" {
  capabilities = ["read"]
}

path "secret/data/custom-mobile-apps/crypto" {
  capabilities = ["read"]
}

path "aws/creds/custom-mobile-apps-signer" {
  capabilities = ["read"]
}