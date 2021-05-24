
def upload_built_app(app_path, customer_name, platform)
  app_basename = File.basename(app_path, '.*')
  app_extension = File.extname(app_path)
  timestamp_string = Time.now.getutc.to_s.gsub(/[^\w]/, '-')
  app_name = "#{app_basename}-#{timestamp_string}#{app_extension}"
  app_key = File.join('builds', customer_name, platform.to_s, app_name)

  bucket = Aws::S3::Resource.new(region: 'us-east-1').bucket('ldf-custom-mobile-apps')
  signer = Aws::S3::Presigner.new
  obj = bucket.object(app_key)
  puts "obj.upload_file(#{app_path}, acl: 'public-read')"
  obj.upload_file(app_path, acl: 'public-read')
  obj.presigned_request(:get_object, acl: 'public-read')
end

