import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // **Before launching finishes, and deliberately not with the engine.**
    // Apple delivers a notification tap to whatever delegate exists at the end
    // of launch and drops it if there is none, so a cold start from a reminder
    // depends on this line running here rather than in
    // `didInitializeImplicitFlutterEngine` below. The channel it feeds can
    // come up whenever — `RemindersChannel.shared` holds the tapped asset id
    // until Dart asks for it.
    //
    // Nothing else in the app claims this delegate. If a plugin ever does —
    // push notifications are the obvious one — the two have to be chained
    // rather than one quietly winning.
    UNUserNotificationCenter.current().delegate = RemindersChannel.shared

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Registered by hand, the way `MainActivity.configureFlutterEngine` does
    // on the other side: this is Shoto's own channel, not a pub package, so
    // nothing generates the line for it.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RemindersChannel") {
      RemindersChannel.register(with: registrar)
    }
  }
}
