# customize and build the iOS application
def build_custom_app(options)
  customer_assets = options[:customer_assets] || ENV['APPIAN_CUSTOMER_ASSETS'] || 'lyndsey'
  customize_build options
  keychain_data = get_keychain_from_vault(
    vault_addr: 'http://127.0.0.1:8200',
    keychain_name: customer_assets
  )

  # get the keychain from Vault so that the app can
  # be signed as the customer.
  #
  # remember, we introduced get_keychain_from_vault in the article
  # Automate Securing Code Signing Assets
  # https://bit.ly/2SPPYTT
  #
  unlock_keychain(
    path: keychain_data[:keychain_path],
    password: keychain_data[:keychain_password],
    set_default: true
  )

  # turn off automatic code signing and set up the provisioning
  # and team id for the application to match that of the customer's
  disable_automatic_code_signing(path: './iOSExample/iOSExample.xcodeproj')
  code_signing_identity = code_signing_identity_from_keychain(keychain_data[:keychain_path])
  update_project_provisioning(
    xcodeproj: './iOSExample/iOSExample.xcodeproj',
    profile: "./iOSExample/Yillyyally.mobileprovision",
    build_configuration: "Release",
    code_signing_identity: code_signing_identity
  )
  update_project_team(
    path: './iOSExample/iOSExample.xcodeproj',
    teamid: '57738V598V'
  )

  # now build the application with the customer's customizations
  # provisioning profiles, and code signing identity
  build_app(
      scheme: 'iOSExample',
      project: './iOSExample/iOSExample.xcodeproj',
      output_directory: 'test_output',
      output_name: 'example.ipa',
      export_options: {
        method: "app-store",
        provisioningProfiles: {
          "com.yilly.yally" => "359e767c-5f71-4b2e-aedd-17645f951e02"
        }
      },
      export_team_id: '57738V598V',
      xcargs: "CODE_SIGN_IDENTITY=\"#{code_signing_identity}\""
  )
end

def code_signing_identity_from_keychain(keychain_filepath)
  identity_output = Fastlane::Actions.sh('security', 'find-identity', '-v', '-p', 'codesigning', keychain_filepath)
  UI.user_error!('Keychain does not contain a single valid signing identity') unless identity_output.match(/1 valid identities found/)
  identity_output.lines.first.chomp.sub(/.*"([^"]+)".*/, '\1')
end
