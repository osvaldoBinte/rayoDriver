import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // WhatsApp Channel
        let whatsappChannel = FlutterMethodChannel(name: "com.tuapp/whatsapp", binaryMessenger: controller.binaryMessenger)
        whatsappChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "openWhatsApp" {
                guard let args = call.arguments as? [String: Any],
                      let urlString = args["url"] as? String,
                      let url = URL(string: urlString) else {
                    result(FlutterError(code: "INVALID_URL",
                                      message: "URL inválida",
                                      details: nil))
                    return
                }
                
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { success in
                        result(success)
                    })
                } else {
                    result(FlutterError(code: "CANT_OPEN_URL",
                                      message: "No se puede abrir WhatsApp",
                                      details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        // Phone Channel
        let phoneChannel = FlutterMethodChannel(name: "com.tuapp/phone", binaryMessenger: controller.binaryMessenger)
        phoneChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "makePhoneCall" {
                guard let args = call.arguments as? [String: Any],
                      let urlString = args["url"] as? String,
                      let url = URL(string: urlString) else {
                    result(FlutterError(code: "INVALID_URL",
                                      message: "URL inválida",
                                      details: nil))
                    return
                }
                
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { success in
                        result(success)
                    })
                } else {
                    result(FlutterError(code: "CANT_OPEN_URL",
                                      message: "No se puede hacer la llamada",
                                      details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}