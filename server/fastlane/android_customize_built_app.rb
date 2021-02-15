require 'yaml'
require_relative 'binary_plist'
require_relative 'android_customize_build'
require 'pry-byebug'

def customize_built_app(options)
  sh('which apktool')
  # we expect that apktool is installed, `brew install apktool`

  # a handy default for quick iterations
  customer_assets = options[:customer_assets] || ENV['APPIAN_CUSTOMER_ASSETS'] || 'puppy'
  customer_assets_dir = File.absolute_path("../#{customer_assets}")
  customer_config_filepath = File.join(customer_assets_dir, "#{customer_assets}.yaml")
  if File.exist?(customer_config_filepath)
    customer_config_file = YAML.load_file(customer_config_filepath)
    welcome_message = customer_config_file['WelcomeMessage'] || 'Hello World!'
    background_color = customer_config_file['BackgroundHexColor'] || '#FFFFFFFF'
  end
  welcome_message = options[:welcome_message] unless options[:welcome_message].nil?
  background_color = options[:background_color] unless options[:background_color].nil?

  example_apk_path = download_latest_release
  # unzip the apk into a tmp directory

  custom_built_app_path = File.expand_path(File.join('~/Desktop', "#{customer_assets}.apk"))
  unsigned_unaligned_temp_apk_path = "#{File.dirname(example_apk_path)}/unsigned_unaligned_temp.apk"
  unsigned_temp_apk_path = "#{File.dirname(example_apk_path)}/unsigned_temp.apk"
  FileUtils.rm_rf([unsigned_unaligned_temp_apk_path, unsigned_temp_apk_path])

  Dir.mktmpdir("customize_built_app") do |unzipped_apk_path|
    Dir.chdir(unzipped_apk_path) do
      FastlaneCore::Helper.show_loading_indicator('Building customized app')
      apktool(
        apk: example_apk_path,
        build: false
      )
      update_app_configuration(
        {
          app_name: customer_assets,
          welcome_message: welcome_message,
          background_color: background_color
        }
      )
      replace_launcher_images(customer_assets_dir)
      apktool(
	apk: unsigned_unaligned_temp_apk_path,
        build: true
      )
      FastlaneCore::Helper.hide_loading_indicator
    end
  end
  keystore_data = get_keystore_from_vault(
    vault_addr: 'http://127.0.0.1:8200',
    keystore_name: 'lyndsey'
  )
  keystore_path = keystore_data[:keystore_path]
  keystore_password = keystore_data[:keystore_password]

  FastlaneCore::Helper.show_loading_indicator('Zip aligning customized app')
  sh(
    command: "zipalign -v -p 4 #{unsigned_unaligned_temp_apk_path} #{unsigned_temp_apk_path}",
    log: false
  )
  FastlaneCore::Helper.hide_loading_indicator
  FastlaneCore::Helper.show_loading_indicator('Signing customized app')
  sh(
    command: "apksigner sign --ks #{keystore_path} --ks-pass pass:'#{keystore_password}' --out #{custom_built_app_path } #{unsigned_temp_apk_path}",
    log: false
  )
  FastlaneCore::Helper.hide_loading_indicator
  puts "Built mobile app: #{custom_built_app_path}"
end

def replace_launcher_images(customer_assets_dir)
  launcher_image_paths = Dir.glob("#{customer_assets_dir}/res/mipmap-*dpi/ic_launcher*.png")
  launcher_image_paths.each do |launcher_image_path|
    mipmap_directory = File.basename(File.dirname(launcher_image_path))
    app_mipmap_directory = File.join(".", "res", mipmap_directory)
    app_mipmap_image_path = File.join(app_mipmap_directory, File.basename(launcher_image_path))
    FileUtils.rm_f(app_mipmap_image_path)
    FileUtils.cp(launcher_image_path, app_mipmap_image_path)
  end
end

def update_app_configuration(options)
  strings_filepaths = Dir.glob('*/**/values*/strings.xml')
  strings_filepaths.each do |strings_filepath|
    customize_build(options.merge(config_filepath: strings_filepath))
  end
end

def apktool(params)
  unzip_command = "decode #{params[:apk]} -o . -f"
  zip_command = "build $(pwd) -o #{params[:apk]} --use-aapt2 "
  command = "apktool #{params[:build] ? zip_command : unzip_command} --frame-path $HOME/Library/apktool/framework"
  sh(command: command, log: false)
end
