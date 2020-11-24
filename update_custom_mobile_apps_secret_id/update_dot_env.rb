#!/usr/bin/env ruby

def update_dot_env_value(key, value)
    dot_env_filepath = '.env'
    content = ''
    if File.exist?(dot_env_filepath)
        content = File.read(dot_env_filepath)
        content.gsub!(/#{key}=.*$\n/, '')
    end
    content << "\n#{key}=#{value}"

    content.gsub!(/^$\n/, '')
    File.open(dot_env_filepath, "w") {|file| file.puts content}
end


if __FILE__ == $0
    key = ARGV[0]
    value = ARGV[1]

    update_dot_env_value(key, value)
end