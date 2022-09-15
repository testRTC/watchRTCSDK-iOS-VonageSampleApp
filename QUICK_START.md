Quick Start
-----------

 1. Get values for your OpenTok **API key**, **session ID**, and **token**.
    See [Obtaining OpenTok Credentials](#obtaining-opentok-credentials)
    for important information.
 
 1. Install CocoaPods as described in [CocoaPods Getting Started](https://guides.cocoapods.org/using/getting-started.html#getting-started).
 
 1. In Terminal, `cd` to your project directory and type `pod install`.
 
 1. Reopen your project in Xcode using the new `.xcworkspace` file.
 
 1. In the ViewController.swift file, replace the following empty strings
    with the corresponding API key, session ID, and token values:
 
     ```swift
     // *** Fill the following variables using your own Project info  ***
     // ***            https://tokbox.com/account/#/                  ***
     // Replace with your OpenTok API key
     let kApiKey = ""
     // Replace with your generated session ID
     let kSessionId = ""
     // Replace with your generated token
     let kToken = ""
     ```
 
 1. Use Xcode to build and run the app on an iOS simulator or device.

## Obtaining OpenTok Credentials

To use the OpenTok platform you need a session ID, token, and API key.
You can get these values by creating a project on your [OpenTok Account
Page](https://tokbox.com/account/) and scrolling down to the Project Tools
section of your Project page. For production deployment, you must generate the
session ID and token values using one of the [OpenTok Server
SDKs](https://tokbox.com/developer/sdks/server/).

## Further Reading

- Check out the Developer Documentation at <https://tokbox.com/developer/>
