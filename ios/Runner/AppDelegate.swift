import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var status: String = "disconnected"
  private var rxBytes: Int64 = 0
  private var txBytes: Int64 = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let methodChannel = FlutterMethodChannel(
        name: "unified_vpn/methods",
        binaryMessenger: controller.binaryMessenger
      )
      methodChannel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "requestRuntimePermissions":
          result(true)
        case "prepareVpn":
          result(true)
        case "start":
          guard
            let args = call.arguments as? [String: Any],
            let rewritten = args["rewrittenConfig"] as? String,
            !rewritten.isEmpty
          else {
            result(
              FlutterError(
                code: "START_FAILED",
                message: "Invalid runtime configuration: missing rewrittenConfig",
                details: nil
              )
            )
            return
          }
          let useTurnMode = (args["useTurnMode"] as? Bool) ?? true
          self.status = "connecting"
          _ = useTurnMode
          self.status = "connected"
          result(nil)
        case "stop":
          self.status = "disconnected"
          result(nil)
        case "status":
          result(self.status)
        case "trafficStats":
          if self.status == "connected" {
            // Placeholder until PacketTunnel statistics are wired from extension.
            self.rxBytes += 1024
            self.txBytes += 768
          }
          result(["rxBytes": self.rxBytes, "txBytes": self.txBytes])
        case "isBatteryOptimizationIgnored":
          result(true)
        case "requestDisableBatteryOptimization":
          result(nil)
        case "listInstalledApps":
          // iOS does not allow enumerating third-party installed apps.
          result([])
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let logsChannel = FlutterEventChannel(
        name: "unified_vpn/logs",
        binaryMessenger: controller.binaryMessenger
      )
      logsChannel.setStreamHandler(LogStreamHandler(
        onListen: { sink in
          sink("iOS: log stream connected")
        },
        onCancel: {}
      ))
    }
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

final class LogStreamHandler: NSObject, FlutterStreamHandler {
  private let onListen: (FlutterEventSink) -> Void
  private let onCancel: () -> Void

  init(onListen: @escaping (FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
    self.onListen = onListen
    self.onCancel = onCancel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onListen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onCancel()
    return nil
  }
}
