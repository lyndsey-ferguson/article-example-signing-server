require 'open-uri'
require 'json'
require 'tempfile'
require 'pry-byebug'

def download_latest_release
  # use GitHub's REST endpoint to download the latest release
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  obj = s3.bucket('ldf-custom-mobile-apps').object('releases/latest/ios.zip')
  # download the release to a temporary file
  zip_package_path = Dir::Tmpname.create(['ios.zip']) {}
  obj.download_file(zip_package_path)
  zip_package_path
end

