require 'pry-byebug'

def build_custom_app(options)
  unsigned_unaligned_apk_path = "../AndroidExample/app/build/outputs/apk/release/app-release-unsigned.apk"
  unsigned_aligned_apk_path = "../AndroidExample/app/build/outputs/apk/release/app-release-unsigned-aligned.apk"
  signed_apk_path = "../AndroidExample/app/build/outputs/apk/release/app-release.apk"
  FileUtils.rm_rf([unsigned_aligned_apk_path, signed_apk_path])
  keystore_data = get_keystore_from_vault(
    vault_addr: 'http://127.0.0.1:8200',
    keystore_name: 'lyndsey'
  )
  keystore_path = keystore_data[:keystore_path]
  keystore_password = keystore_data[:keystore_password]
  gradle(
    project_dir: "AndroidExample",
    task: "assemble",
    build_type: "Release",
    print_command: true,
    properties: {
      "android.injected.signing.store.file" => keystore_path,
      "android.injected.signing.store.password" => keystore_password
    }
  )
end
