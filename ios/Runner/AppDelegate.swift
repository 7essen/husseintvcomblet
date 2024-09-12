import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // قم بإزالة أو تعليق FirebaseApp.configure() و Messaging.messaging().delegate
    // FirebaseApp.configure()
    // Messaging.messaging().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // قم بإزالة هذا الميثود إذا لم تعد تستخدم Firebase Messaging
  // func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
  //   Messaging.messaging().apnsToken = deviceToken
  // }
}
