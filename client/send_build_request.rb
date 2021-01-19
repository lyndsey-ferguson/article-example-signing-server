#!/usr/bin/env ruby

require 'aws-sdk'
require 'dotenv/load'
require 'tmpdir'

Dotenv.load('../.env')

sqs = Aws::SQS::Client.new(region: 'us-east-1')

URL = 'https://sqs.us-east-1.amazonaws.com/492939359554/CustomMobileAppsQueue'

company = 'puppy'

# all I have to do is create a temporary zip file from the puppy directory
company_assets_zip = Dir::Tmpname.create([company, '.zip']) {}

Dir.chdir(File.join(__dir__, company)) do
  `zip -qr #{company_assets_zip} .`
  puts company_assets_zip
end

s3 = Aws::S3::Resource.new(region: 'us-east-1')
obj_key = File.join('requests', File.basename(company_assets_zip))
obj = s3.bucket('ldf-custom-mobile-apps').object(obj_key)
obj.upload_file(company_assets_zip)

# what do I need to send?
# 1. the images
# 2. the xml properties file
# 3. the name of the company

message = {
  company: company,
  request_payload: obj_key
}

sqs.send_message(
  queue_url: URL,
  message_body: message.to_json
)