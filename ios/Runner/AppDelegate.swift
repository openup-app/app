import UIKit
import Flutter
import flutter_callkit_voximplant
import flutter_voip_push_notification
import PushKit
import CallKit
import AVFAudio

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
//    FlutterVoipPushNotificationPlugin.didReceiveIncomingPush(with: payload, forType: type.rawValue)
      processPush(with: payload.dictionaryPayload, and: completion);
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    FlutterVoipPushNotificationPlugin.didUpdate(pushCredentials, forType: type.rawValue);
  }

  private func processPush(with payload: Dictionary<AnyHashable, Any>, and completion: (() -> Void)?) {
    guard let ridString = payload["rid"] as? String,
          let rid = UUID(uuidString: ridString),
          let callerUid = payload["callerUid"] as? String,
          let callerName = payload["callerName"] as? String,
          let photo = payload["callerPhoto"] as? String
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
