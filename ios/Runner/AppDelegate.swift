import UIKit
import Firebase
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate : FlutterAppDelegate {
  var notificationTokenStreamHandler: NotificationTokenStreamHandler?;

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    self.notificationTokenStreamHandler = NotificationTokenStreamHandler(controller);

    // Google Mobile Services for using Google Maps
    GMSServices.provideAPIKey("AIzaSyBgwJH4Tz0zMjPJLU5F9n4k2iuneDN1OmM");

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Token for Firebase Auth, see: https://github.com/firebase/flutterfire/issues/4970#issuecomment-894834223
    Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)

    // Further use of push notification token in Flutter app
    self.notificationTokenStreamHandler?.onToken(deviceToken);
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Let FirebaseAuth handle push notification, see: https://github.com/firebase/flutterfire/issues/4970#issuecomment-894834223ß
    if (Auth.auth().canHandleNotification(userInfo)){
        print(userInfo)
        return
    }
    // Other plugins to handle push notifications
  }
}

/// Notifies the Flutter app about APNs tokens via an EventChannel.
class NotificationTokenStreamHandler : NSObject, FlutterStreamHandler {
  var eventChannel: FlutterEventChannel?;
  var eventSink: FlutterEventSink?;
  var deviceToken: Data?;

  init(_ controller: FlutterViewController) {
    super.init();
    self.eventChannel = FlutterEventChannel(name: "com.openupdating/notification_tokens", binaryMessenger: controller.binaryMessenger);
    self.eventChannel?.setStreamHandler(self);
  }

  public func onToken(_ deviceToken: Data) {
    self.deviceToken = deviceToken;
    self.eventSink?(deviceToken.hexString);
  }

  // Handle EventChannel
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events;
    if let deviceToken = self.deviceToken {
      onToken(deviceToken);
    }
    return nil
  }

  // Handler for EventChannel
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil;  
  }
}

extension Data {
  var hexString: String {
    let hexString = map { String(format: "%02.2hhx", $0) }.joined()
    return hexString
  }
}
