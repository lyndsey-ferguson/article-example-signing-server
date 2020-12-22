#!/usr/bin/env ruby

require 'aws-sdk'
require 'date'
require 'dotenv'
require 'tmpdir'
require 'vault'
require 'byebug'

Dotenv.load(File.join(__dir__, '.env'))

Vault.address = 'http://127.0.0.1:8200'
Vault.auth.approle(
  ENV['VAULT_CODESIGNING_ROLE_ID'],
  ENV['VAULT_CODESIGNING_SECRET_ID']
)
aws_secret = Vault.logical.read('aws/creds/custom-mobile-apps-signer')
sleep 10 # give time for the IAM credentials to become valid
Aws.config.update({
  credentials: Aws::Credentials.new(
    aws_secret.data[:access_key],
    aws_secret.data[:secret_key]
  )
})

sqs = Aws::SQS::Client.new(region: 'us-east-1')

URL = 'https://sqs.us-east-1.amazonaws.com/492939359554/CustomMobileAppsQueue'

poller = Aws::SQS::QueuePoller.new(URL)

s3 = Aws::S3::Resource.new(region: 'us-east-1')

poller.poll do |msg|
  build_request = JSON.parse(msg.body)
  puts build_request

  obj = s3.bucket('ldf-custom-mobile-apps').object(build_request['request_payload'])
  company_assets_zip = Dir::Tmpname.create(['downloaded', '.zip']) {}
  obj.get(response_target: company_assets_zip)
  puts company_assets_zip

end