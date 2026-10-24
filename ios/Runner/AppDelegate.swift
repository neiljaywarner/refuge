import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let badgeChannel = FlutterMethodChannel(
        name: "com.belongonthespectrum.sanctuary/badge",
        binaryMessenger: messenger
      )
      badgeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "setBadgeCount" {
          let count = (call.arguments as? [String: Any])?["count"] as? Int ?? 0
          if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(max(0, count)) { error in
              result(error == nil)
            }
          } else {
            UIApplication.shared.applicationIconBadgeNumber = max(0, count)
            result(true)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
