import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "noddle_channel", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "giveResponse":
        do {
          // Extract parameters from the method call
          let message = call.arguments as? [String: Any]
          let userMessage = message?["message"] as? String ?? ""
          let taskFilePath = message?["taskFilePath"] as? String ?? ""
          let sessionId = message?["sessionId"] as? Int
          let queryType = message?["queryType"] as? String ?? ""
          let hasImage = message?["hasImage"] as? Bool ?? false
          let imagePath = message?["imagePath"] as? String
          
          // Log the received data
          print("NoddleChannel: Message received: \(userMessage)")
          print("NoddleChannel: Task file path: \(taskFilePath)")
          print("NoddleChannel: Session ID: \(sessionId ?? 0)")
          print("NoddleChannel: Query type: \(queryType)")
          print("NoddleChannel: Has image: \(hasImage)")
          print("NoddleChannel: Image path: \(imagePath ?? "nil")")
          
          // For now, return a simple response acknowledging receipt
          let response = "Message received with status: true. I'm processing your request: '\(userMessage)'"
          
          // Return success response
          result(response)
          
        } catch {
          print("NoddleChannel: Error processing method call: \(error)")
          result(FlutterError(code: "ERROR", message: "Failed to process request", details: error.localizedDescription))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
