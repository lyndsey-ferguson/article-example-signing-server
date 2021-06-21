#!/usr/bin/env ruby

require 'octokit'
require 'tmpdir'
require 'yaml'

puts "New build request"
issue_number = ARGV[0]

issue_number = "1"
github_token = ENV["GITHUB_TOKEN"]

client = Octokit::Client.new(:access_token => github_token)

issue = client.issue("lyndsey-ferguson/article-example-signing-server", issue_number)
puts issue.body

zipfile_urls = []
issue.body.each_line do |line|
  m = line.match(/\[\S+.zip\]\((?<zipfile_url>\S+.zip)\)/)
  if m
    zipfile_urls << m[:zipfile_url]
  end
end

raise "Error: expecting one configuration zip file, but found #{zipfile_urls.length}." if zipfile_urls.length != 1
Dir.mktmpdir do |workspace|
  puts "created the tmpdir #{workspace}"
  Dir.chdir(workspace) do
    response = client.get(zipfile_urls.first)
    File.open('config.zip', 'wb') { |f| f.write(response) }
    `unzip -o -q config.zip`
    yamls = Dir.glob('*.yaml')
    
    raise "Error: expected one yaml config file, but found #{yamls}." if yamls.length != 1

    config = YAML.load(File.read(yamls.first))
    puts config
  end
end
puts "Done processing request"
