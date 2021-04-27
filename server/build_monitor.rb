#!/usr/bin/env ruby

require 'aws-sdk'
require 'date'
require 'dotenv'
require 'fastlane'
require 'tmpdir'
require 'vault'
require 'byebug'
require 'zip'

Dotenv.load(File.join(__dir__, '.env'))

Vault.address = 'http://127.0.0.1:8200'
Vault.auth.approle(
  ENV['VAULT_CODESIGNING_ROLE_ID'],
  ENV['VAULT_CODESIGNING_SECRET_ID']
)

fastlane_dir = File.join(__dir__, 'fastlane')
Dir.chdir(fastlane_dir) do
  Fastlane.load_actions
  Fastlane.plugin_manager.load_plugins

  aws_secret = Vault.logical.read('aws/creds/custom-mobile-apps-signer')
  sleep 10 # give time for the IAM credentials to become valid
  Aws.config.update({
    credentials: Aws::Credentials.new(
      aws_secret.data[:access_key],
      aws_secret.data[:secret_key]
    )
  })

  sqs = Aws::SQS::Client.new(region: 'us-east-1')

  REQUEST_QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/492939359554/CustomMobileAppsQueue'

  poller = Aws::SQS::QueuePoller.new(REQUEST_QUEUE_URL)

  s3 = Aws::S3::Resource.new(region: 'us-east-1')

  poller.poll do |msg|
    Dotenv.load(File.join(__dir__, '.env'))
    Vault.auth.approle(
      ENV['VAULT_CODESIGNING_ROLE_ID'],
      ENV['VAULT_CODESIGNING_SECRET_ID']
    )
    ENV['VAULT_APPROLE_ROLE_ID'] = ENV['VAULT_CODESIGNING_ROLE_ID']
    ENV['VAULT_APPROLE_SECRET_ID'] = ENV['VAULT_CODESIGNING_SECRET_ID']

    build_request = JSON.parse(msg.body)
    puts build_request

    obj = s3.bucket('ldf-custom-mobile-apps').object(build_request['request_payload'])
    company_assets_zip = Dir::Tmpname.create(['downloaded', '.zip']) {}
    obj.get(response_target: company_assets_zip)
    company_name = build_request['company']
    puts "company, #{company_name}, assets zip file path: #{company_assets_zip}"

    company_assets_dir = Dir::Tmpname.create([company_name]) {}
    
    FileUtils.mkdir_p(company_assets_dir)
    Dir.chdir(company_assets_dir) do
      Zip::File.open(company_assets_zip) do |zip_file|
        zip_file.each { |file| file.extract(file.name) }
      end
    end
    FileUtils.rm(company_assets_zip)

    fastfile = Fastlane::FastFile.new('Fastfile')

    output_build = fastfile.runner.execute(
      :customize_built_app,
      :ios,
      customer_name: company_name,
      assets_dir: company_assets_dir,
      signed: true
    )
  end
end
