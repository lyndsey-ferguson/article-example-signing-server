#!/usr/bin/env ruby

require 'aws-sdk'
require 'dotenv/load'
require 'tmpdir'

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