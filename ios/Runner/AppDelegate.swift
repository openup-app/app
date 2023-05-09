import UIKit
import Firebase
import Flutter
import flutter_callkit_voximplant
import flutter_voip_push_notification
import PushKit
import CallKit
import AVFAudio
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, FlutterStreamHandler {
  var eventChannel: FlutterEventChannel?;
  var notificationTokenEventSink: FlutterEventSink?;

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBgwJH4Tz0zMjPJLU5F9n4k2iuneDN1OmM");
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Fix for Flutter package:flutter_webrtc being muted and silent when
    // answering from the background. Should be done by package instead.
    // See: https://github.com/flutter-webrtc/flutter-webrtc/issues/816#issuecomment-1119980562
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .voiceChat, options: [])
    } catch (let error) {
      print("Error while configuring audio session: \(error)")
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    self.eventChannel = FlutterEventChannel(name: "com.openupdating/notification_tokens", binaryMessenger: controller.binaryMessenger);
    self.eventChannel?.setStreamHandler(self);

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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
    return nil
  }

  // Handler for EventChannel
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil;  
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType) {
      processPush(with: payload.dictionaryPayload, and: nil);
  }
    
  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
      processPush(with: payload.dictionaryPayload, and: completion);
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    FlutterVoipPushNotificationPlugin.didUpdate(pushCredentials, forType: type.rawValue);
  }

  private func processPush(with payload: Dictionary<AnyHashable, Any>, and completion: (() -> Void)?) {
    let body = payload["body"] as! Dictionary<AnyHashable, Any>
     guard let ridString = body["rid"] as? String,
          let rid = UUID(uuidString: ridString),
          let callerUid = body["uid"] as? String,
          let callerName = body["name"] as? String,
          let photo = body["photo"] as? String
          else {
              return
    }

    // Write to disk to pass to Flutter side in case it has not yet started
    let handle = "\(callerUid)#_\(photo)#_\(callerName)";
    let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let dirPath = dirPaths[0];
    let filename = dirPath.appendingPathComponent("incoming_call.txt")
    do {
      try handle.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        let callUpdate = CXCallUpdate()
        callUpdate.localizedCallerName = callerName;
        callUpdate.remoteHandle = CXHandle(type: CXHandle.HandleType.generic, value: handle);
        let configuration = CXProviderConfiguration(localizedName: "ExampleLocalizedName")
        FlutterCallkitPlugin.sharedInstance.reportNewIncomingCall(with: rid, callUpdate: callUpdate, providerConfiguration: configuration, pushProcessingCompletion: completion)
    } catch {
      // Ignored
    }
  }
}

struct CallNotification: Decodable {
    let uid: String
    let photo: String
    let name: String
    let rid: String
}

extension Data {
  var hexString: String {
    let hexString = map { String(format: "%02.2hhx", $0) }.joined()
    return hexString
  }
}
