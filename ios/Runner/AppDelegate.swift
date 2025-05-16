import UIKit
import Flutter
import GoogleMaps
import FirebaseMessaging
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBAVJDSpCXiLRhVTq-MA3RgZqbmxm1wD1I")
        
        // Inicializar Firebase
        FirebaseApp.configure()
        
        // Configurar el delegado de mensajería de Firebase
        Messaging.messaging().delegate = self
        
        // Solicitar permiso para notificaciones
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // Registrar para notificaciones remotas
        application.registerForRemoteNotifications()

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Canal para notificaciones
        let notificationsChannel = FlutterMethodChannel(name: "com.tuapp/notifications", binaryMessenger: controller.binaryMessenger)
        notificationsChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getToken" {
                Messaging.messaging().token { token, error in
                    if let error = error {
                        result(FlutterError(code: "TOKEN_ERROR",
                                          message: error.localizedDescription,
                                          details: nil))
                        return
                    }
                    
                    if let token = token {
                        result(token)
                    } else {
                        result(FlutterError(code: "NO_TOKEN",
                                          message: "No se pudo obtener el token",
                                          details: nil))
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
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
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "makePhoneCall":
                self?.handleRegularCall(call: call, result: result)
            case "makeEmergencyCall":
                self?.handleEmergencyCall(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleRegularCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    }
    
    private func handleEmergencyCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String else {
            result(FlutterError(code: "INVALID_URL",
                              message: "URL inválida",
                              details: nil))
            return
        }
        
        // Asegurarse de que la URL tenga el formato correcto para llamadas
        let cleanedUrlString = urlString.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: cleanedUrlString) else {
            result(FlutterError(code: "INVALID_URL",
                              message: "URL inválida",
                              details: nil))
            return
        }
        
        // Verificar si se puede hacer la llamada
        if UIApplication.shared.canOpenURL(url) {
            // En iOS, tel: y telprompt: son diferentes
            // telprompt: inicia la llamada directamente
            if let directCallUrl = URL(string: cleanedUrlString.replacingOccurrences(of: "tel:", with: "telprompt:")) {
                UIApplication.shared.open(directCallUrl, options: [:]) { success in
                    if success {
                        result(true)
                    } else {
                        result(FlutterError(code: "CALL_FAILED",
                                          message: "No se pudo iniciar la llamada de emergencia",
                                          details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_URL",
                                  message: "No se pudo crear la URL para llamada directa",
                                  details: nil))
            }
        } else {
            result(FlutterError(code: "CANT_OPEN_URL",
                              message: "No se puede hacer la llamada de emergencia",
                              details: nil))
        }
    }
    
    // Recibir token actualizado
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}

