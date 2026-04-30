import Flutter
import UIKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    
  private let channelName = "com.bizwho.callerid/role_manager"
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    // iOS MethodChannel 핸들러 등록
    guard let binaryMessenger = (engineBridge.pluginRegistry.registrar(forPlugin: "AppDelegate")?.messenger()) else { return }
    
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
        
      case "syncCallKitContacts":
        // Flutter에서 연락처 맵을 받아 App Group UserDefaults에 저장
        guard let args = call.arguments as? [String: Any],
              let contacts = args["contacts"] as? [String: String] else {
          result(FlutterError(code: "INVALID_ARGS", message: "contacts 딕셔너리가 없습니다.", details: nil))
          return
        }
        
        // App Group UserDefaults에 저장 (CallDirectoryExtension과 공유)
        if let defaults = UserDefaults(suiteName: "group.com.bizwho.callerid") {
          defaults.set(contacts, forKey: "caller_id_contacts")
          defaults.synchronize()
          
          // CallKit Extension에 데이터 갱신 요청
          CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.bizwho.callerid.CallDirectoryExtension") { error in
            if let error = error {
              NSLog("[BizWho] CallKit Extension 재로드 실패: \(error.localizedDescription)")
            } else {
              NSLog("[BizWho] CallKit Extension 재로드 완료: \(contacts.count)건")
            }
          }
          result(true)
        } else {
          result(FlutterError(code: "APP_GROUP_ERROR", message: "App Group UserDefaults를 초기화할 수 없습니다. Xcode에서 App Group 설정을 확인하세요.", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
