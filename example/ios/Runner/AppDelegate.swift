import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let lifecycleChannel = FlutterBasicMessageChannel(
        name: "mana/demo/lifecycle",
        binaryMessenger: controller.binaryMessenger,
        codec: FlutterStringCodec.sharedInstance()
      )
      let keyboardChannel = FlutterBasicMessageChannel(
        name: "mana/demo/keyboard",
        binaryMessenger: controller.binaryMessenger,
        codec: FlutterJSONMessageCodec.sharedInstance()
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        lifecycleChannel.sendMessage("resumed")
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        keyboardChannel.sendMessage(["type": "keydown"])
      }

      let streamChannel = FlutterEventChannel(name: "mana/demo/stream", binaryMessenger: controller.binaryMessenger)
      streamChannel.setStreamHandler(DemoStreamHandler())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class DemoStreamHandler: NSObject, FlutterStreamHandler {
  private var timer: Timer?
  private var count: Int = 0
  private var sink: FlutterEventSink?
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.count += 1
      self.sink?(["type": "tick", "count": self.count, "ts": Int(Date().timeIntervalSince1970 * 1000)])
    }
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    sink = nil
    return nil
  }
}
