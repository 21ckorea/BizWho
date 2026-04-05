import UIKit
import Flutter
import CallKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.caller_id/role_manager",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "reloadExtension" {
        self.reloadCallDirectoryExtension(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func reloadCallDirectoryExtension(result: @escaping FlutterResult) {
    CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: "com.example.caller-id-v01.CallDirectoryExtension") { (status, error) in
        if let error = error {
            result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
            return
        }
        
        // 익스텐션 강제 리로드 요청
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.example.caller-id-v01.CallDirectoryExtension") { (error) in
            if let error = error {
                result(FlutterError(code: "RELOAD_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(true)
            }
        }
    }
  }
}
