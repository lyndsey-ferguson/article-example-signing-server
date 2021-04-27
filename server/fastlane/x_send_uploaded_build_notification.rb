BUILD_COMPLETE_QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/492939359554/BuiltCustomMobileAppsQueue'

def send_uploaded_build_notification(uploaded_s3_path, customer_name)
  sqs = Aws::SQS::Client.new(region: 'us-east-1')
  message = {
    company: customer_name,
    output_build: uploaded_s3_path
  }
  sqs.send_message(
    queue_url: BUILD_COMPLETE_QUEUE_URL,
    message_body: message.to_json
  )
end

