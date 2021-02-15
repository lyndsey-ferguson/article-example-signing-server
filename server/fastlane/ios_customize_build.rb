# method to configure the iOS application’s welcome message and background color
def customize_build(options)
  welcome_message = options[:welcome_message] || 'Hello World!'
  background_color = options[:background_color] || '#FFFFFFFF'
  config_filepath = options[:config_filepath] || '../iOSExample/iOSExample/configurations.plist'

  update_plist(
    plist_path: config_filepath,
    block: proc do |plist|
      plist[:WelcomeMessage] = welcome_message
      plist[:BackgroundHexColor] = background_color
    end
  )
end
