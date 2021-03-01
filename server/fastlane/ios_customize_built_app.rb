require 'yaml'
require_relative 'binary_plist'
require_relative 'ios_customize_build'


def customize_built_app(options)
  # a handy default for quick iterations
  customer_assets = options[:customer_name] || ENV['APPIAN_CUSTOMER_ASSETS'] || 'puppy'
  customer_assets_dirpath = options[:assets_dir]

  customer_appiconset_dirpath = File.absolute_path("#{customer_assets_dirpath}/#{customer_assets}.appiconset")
  customer_profile_pathname = File.absolute_path("#{customer_assets_dirpath}/#{customer_assets}.mobileprovision")
  zip_package_path = download_latest_release()

  custom_built_app_path = File.expand_path(File.join('~/Desktop', "#{customer_assets}.ipa"))

  # unzip the combined ipa & images package into a tmp director
  Dir.mktmpdir("latest_release_pkg") do |latest_release_pkg_path|
    Dir.chdir(latest_release_pkg_path) do
      sh("unzip -o -q #{zip_package_path}")

      example_ipa_filepath = File.absolute_path('example.ipa')
      app_iconset_dirpath = File.absolute_path('AppIcon.appiconset')

      # now that we have the package unzipped into a temporary folder
      # lets unzip the ipa so we can operate inside of it
      Dir.mktmpdir("customize_built_app") do |unzipped_ipa_path|
        Dir.chdir(unzipped_ipa_path) do
          sh("unzip -o -q #{example_ipa_filepath}")

          # Load the customer’s settings from a YAML settings file
          customer_config_filepath = File.absolute_path("#{customer_assets_dirpath}/#{customer_assets}.yaml")
          if File.exist?(customer_config_filepath)
            customer_config_file = YAML.load_file(customer_config_filepath)
            welcome_message = customer_config_file['WelcomeMessage'] || 'Hello World!'
            background_color = customer_config_file['BackgroundHexColor'] || '#FFFFFFFF'
          end
          welcome_message = options[:welcome_message] unless options[:welcome_message].nil?
          background_color = options[:background_color] unless options[:background_color].nil?

          example_ipa_payload_dir = File.join(unzipped_ipa_path, "Payload")
          app_bundle_path = File.join(example_ipa_payload_dir, 'AppExample.app')
          configurations_plist_filepath = File.join(app_bundle_path, 'configurations.plist')

          # Apple stores the xml plist files in a binary format in order to
          # save space. We need to operate on a plain text file, so we use
          # the plutil tool to convert it to XML.
          sh("plutil -convert xml1 #{configurations_plist_filepath}")
          customize_build(
            welcome_message: welcome_message,
            background_color: background_color,
            config_filepath: configurations_plist_filepath
          )
          # Convert the text plist XML file back to a binary XML file
          sh("plutil -convert binary1 #{configurations_plist_filepath}")

          copy_customer_images(customer_appiconset_dirpath, latest_release_pkg_path)
          compile_images(latest_release_pkg_path, example_ipa_payload_dir)

          keychain_data = get_keychain_from_vault(
            vault_addr: 'http://127.0.0.1:8200',
            keychain_name: customer_assets
          )
          keychain_password = keychain_data[:keychain_password]
          keychain_path = keychain_data[:keychain_path]

          unlock_keychain(path: keychain_path, password: keychain_password, set_default: true)
          cert = certificate_id_from_keychain(keychain_path)
          sign_frameworks(cert, keychain_path)
          prepare_app_bundle(app_bundle_path, customer_profile_pathname)
          prepare_entitlements(cert, app_bundle_path, keychain_path, customer_profile_pathname)
          sh("zip -qr #{custom_built_app_path} .")
        end
      end
    end
  end
  puts "Built mobile app: #{custom_built_app_path}"
end


APP_ICON_ASSET_DIR = 'AppIcon.appiconset'

def app_icon_asset_path(latest_release_pkg_path)
  File.join(latest_release_pkg_path, APP_ICON_ASSET_DIR)
end

def copy_customer_images(customer_appiconset_dirpath, latest_release_pkg_path)
  remove_app_icon_assets(latest_release_pkg_path)
  FileUtils.cp_r("#{customer_appiconset_dirpath}/.", app_icon_asset_path(latest_release_pkg_path))
end

# remove pre-existing application icons just in case the
# customer did not provide an icon for one of the many
# resolutions that iOS applications support. We do not want
# the standard icon to appear for those resolutions.
def remove_app_icon_assets(latest_release_pkg_path)
   FileUtils.rm_r(Dir.glob("#{app_icon_asset_path(latest_release_pkg_path)}/*.png"))
end

# the `xcrun actool` requires the minimum deployment target
# as one of its command line options. Rather than hard-coding
# it, we get that value from the application Info.plist.
def minimum_deployment_target
  plist_filepath = 'Payload/AppExample.app/Info.plist'
  temporary_plist_file = Tempfile.new
  FileUtils.cp(plist_filepath, temporary_plist_file.path)
  info_plist = Plist.parse_binary_xml(temporary_plist_file.path)
  info_plist.fetch('MinimumOSVersion', '10.0')
end

def compile_images(latest_release_pkg_path, example_ipa_payload_dir)
  FileUtils.mkdir_p("#{latest_release_pkg_path}/build")
  command = "xcrun actool #{latest_release_pkg_path} "
  command += "--compile #{example_ipa_payload_dir}/AppExample.app "
  command += "--minimum-deployment-target #{minimum_deployment_target} "
  command += '--app-icon AppIcon --platform iphoneos '
  command += "--output-partial-info-plist #{latest_release_pkg_path}/build/partial.plist "
  sh(command)
end

# find the certificate in the keychain so that we can get the
# id and use it for code signing.
def certificate_id_from_keychain(keychain_filepath)
  identity_output = Fastlane::Actions.sh('security', 'find-identity', '-v', '-p', 'codesigning', keychain_filepath)
  UI.user_error!('Keychain does not contain a single valid signing identity') unless identity_output.match(/1 valid identities found/)
  identity_output.lines.first.split[1].downcase
end

# sign any frameworks inside of the application
def sign_frameworks(cert, keychain_filepath)
  frameworks = Dir.glob('Payload/AppExample.app/Frameworks/*.dylib').map { |s| "'#{s}'" }.join(' ')
  unless frameworks.empty?
    sh("/usr/bin/codesign -f --keychain \"#{keychain_filepath.shellescape}\"  -s \"#{cert}\" #{frameworks}")
  end
end

# remove any existing signature and put the provisioning profile
# inside of the app bundle
def prepare_app_bundle(app_bundle_path, profile_pathname)
  # Remove existing signature file
  FileUtils.rm_rf("#{app_bundle_path}/_CodeSignature")

  # Copy associated provisioning profile to app
  FileUtils.cp(profile_pathname, "#{app_bundle_path}/embedded.mobileprovision")
end

# create a plist from the provisioning profile so that we
# can get the team id and the application bundle id
def plist_for_profile(profile)
  output_plist_file = Tempfile.new
  `security cms -D -i \"#{profile}\" > \"#{output_plist_file.path}\"` if File.exists?(profile)
  Plist.parse_xml(output_plist_file) || {}
end

# customize the entitlements file with values from the customer's
# mobileprovision file.
def customize_entitlements_xml(xml_path, customer_app_id, customer_team_id)
  xml_hash = Plist.parse_xml(xml_path)

  xml_hash['application-identifier'] = customer_app_id
  xml_hash['com.apple.developer.team-identifier'] = customer_team_id if xml_hash.key?('com.apple.developer.team-identifier')

  xml_hash.save_plist(xml_path)
end

# pull out the application's existing entitlements and customize the values that
# are associated with the customer, and then re-embed them into the application binary
def prepare_entitlements(cert, app_bundle_path, keychain_filepath, mobileprovisioning_filepath)
  # File exists in builds that were created with xcode versions < 10.
  # Entitlements are now embedded in the app binary which are read and manipulated before signing them back into the binary.
  FileUtils.rm_f("#{app_bundle_path}/#{File.basename(app_bundle_path, '.*')}.entitlements")
  entitlements = Tempfile.new()
  sh("/usr/bin/codesign -d --entitlements :\"#{entitlements.path}\" \"#{app_bundle_path}\"")
  mobileprovisioning_data = plist_for_profile(mobileprovisioning_filepath)
  team_id = mobileprovisioning_data.dig('Entitlements', 'com.apple.developer.team-identifier')
  app_id = mobileprovisioning_data.dig('Entitlements', 'application-identifier').sub("#{team_id}.", '')
  customize_entitlements_xml(entitlements.path, app_id, team_id)
  sh("/usr/bin/codesign -f --keychain \"#{keychain_filepath.shellescape}\" -s \"#{cert}\" --entitlements \"#{entitlements.path}\" \"#{app_bundle_path}\"")
end

