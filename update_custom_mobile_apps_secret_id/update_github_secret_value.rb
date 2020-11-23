#!/usr/bin/env ruby

require 'vault'
require "rbnacl"
require "base64"
require 'octokit'
require 'optparse'

def create_box(public_key)
  b64_key = RbNaCl::PublicKey.new(Base64.decode64(public_key[:key]))
  {
    key_id: public_key[:key_id],
    box: RbNaCl::Boxes::Sealed.from_public_key(b64_key)
  }
end

def update_secret_value(secret_key, secret_value)
  github_token = File.read(File.join(__dir__, 'update-public-repos-token.txt'))
  github_client = Octokit::Client.new(:access_token => github_token)
  repo = github_client.repository('lyndsey-ferguson/article-example-customize-existing-mobile-app')
  puts "working with repo: #{repo.url}"
  box = create_box(github_client.get("#{repo.url}/actions/secrets/public-key"))
  encrypted = box[:box].encrypt(secret_value)
  response = github_client.put("#{repo.url}/actions/secrets/#{secret_key}",
    encrypted_value: Base64.strict_encode64(encrypted),
    key_id: box[:key_id]
  )
end

if __FILE__ == $0
  secret_key = ARGV[0]
  secret_value = ARGV[1]

  update_secret_value(secret_key, secret_value)
end
