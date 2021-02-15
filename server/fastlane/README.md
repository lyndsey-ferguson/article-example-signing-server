fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios customize_build
```
fastlane ios customize_build
```
configures the background color of the application, along with the welcome message
### ios build_custom_app
```
fastlane ios build_custom_app
```
customize and build the iOS application
### ios download_latest_release
```
fastlane ios download_latest_release
```
download the latest released app for iOS
### ios customize_built_app
```
fastlane ios customize_built_app
```
download, customize, and sign the app according to customer's needs

----

## Android
### android customize_build
```
fastlane android customize_build
```

### android build_custom_app
```
fastlane android build_custom_app
```

### android download_latest_release
```
fastlane android download_latest_release
```

### android customize_built_app
```
fastlane android customize_built_app
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
