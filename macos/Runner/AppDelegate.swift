import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Set up method channel
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "noodle_channel", binaryMessenger: controller.binaryMessenger)
    
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
          print("NoodleChannel: Message received: \(userMessage)")
          print("NoodleChannel: Task file path: \(taskFilePath)")
          print("NoodleChannel: Query type: \(queryType)")
          print("NoodleChannel: Has image: \(hasImage)")
          print("NoodleChannel: Image path: \(imagePath ?? "nil")")
          
          // For now, return a simple response acknowledging receipt
          let response = "Message received with status: true. I'm processing your request: '\(userMessage)'"
          
          // Return success response
          result(response)
          
        } catch {
          print("NoodleChannel: Error processing method call: \(error)")
          result(FlutterError(code: "ERROR", message: "Failed to process request", details: error.localizedDescription))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
