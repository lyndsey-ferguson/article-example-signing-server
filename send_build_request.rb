#!/usr/bin/env ruby

require 'aws-sdk'
require 'dotenv/load'

sqs = Aws::SQS::Client.new(region: 'us-east-1')

URL = 'https://sqs.us-east-1.amazonaws.com/492939359554/CustomMobileAppsQueue'

# what do I need to send?
# 1. the images
# 2. the xml properties file
# 3. the name of the company
sqs.send_message_batch({
  queue_url: URL,
  entries: [
    {
      id: 'msg1',
      message_body: 'Hello world'
    },
    {
      id: 'msg2',
      message_body: 'How is the weather?'
    }
  ],
})