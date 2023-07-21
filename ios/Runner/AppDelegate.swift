import UIKit
import Firebase
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  var eventChannel: FlutterEventChannel?;
  var notificationTokenEventSink: FlutterEventSink?;
  var deviceToken: Data?;

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBgwJH4Tz0zMjPJLU5F9n4k2iuneDN1OmM");
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    self.eventChannel = FlutterEventChannel(name: "com.openupdating/notification_tokens", binaryMessenger: controller.binaryMessenger);
    self.eventChannel?.setStreamHandler(self);

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    self.deviceToken = deviceToken;
    // Token for Firebase Auth, see: https://github.com/firebase/flutterfire/issues/4970#issuecomment-894834223
    Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
    
    // Token to handle ourselves in Dart
    self.notificationTokenEventSink?(deviceToken.hexString);
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Let FirebaseAuth handle push notification, see: https://github.com/firebase/flutterfire/issues/4970#issuecomment-894834223ß
    if (Auth.auth().canHandleNotification(userInfo)){
        print(userInfo)
        return
    }
    // Other plugins to handle push notifications
  }

  // Handle EventChannel
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.notificationTokenEventSink = events;
    if let deviceToken = self.deviceToken {
      events(deviceToken.hexString);
    }
    return nil
  }

  // Handler for EventChannel
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil;  
  }


}

extension Data {
  var hexString: String {
    let hexString = map { String(format: "%02.2hhx", $0) }.joined()
    return hexString
  }
}
