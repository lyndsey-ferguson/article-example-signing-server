require 'json'
require 'aws-sdk'

def lambda_handler(event: , context:)
    batch_processes=[]
    puts event.to_json
    event['Records'].each do |record|
        publish_message(JSON.parse(record['body']))
    end
end

def publish_message(message)
    sns = Aws::SNS::Client.new
    
    company = message['company']
    build_url = message['build_url']
    
    subject = "A new mobile app for #{company} has been created"
    message = """
A new build has been created for #{company}. Please visit #{build_url} to download the app.
    """
    response = sns.publish(
        topic_arn: 'arn:aws:sns:us-east-1:492939359554:BuiltCustomMobileAppEmailSNS',    
        message: message,
        subject: subject
    )
 
    # Print out the response
    puts(response)
end
