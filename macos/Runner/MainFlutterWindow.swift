import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var status: String = "disconnected"
  private var rxBytes: Int64 = 0
  private var txBytes: Int64 = 0
  private var eventSink: FlutterEventSink?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let methodChannel = FlutterMethodChannel(
      name: "unified_vpn/methods",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "requestRuntimePermissions":
        // Network Extension + App Group must be enabled in Xcode; first VPN connect shows system approval.
        result(true)
      case "prepareVpn":
        // WireGuard plugin will prompt for VPN approval on first tunnel start if needed.
        result(true)
      case "start":
        let args = call.arguments as? [String: Any]
        let useTurnMode = (args?["useTurnMode"] as? Bool) ?? true
        self.status = "connected"
        self.eventSink?("macOS: mode = \(useTurnMode ? "WG+TURN" : "WG")")
        self.eventSink?("macOS: start requested (native adapter integration point)")
        result(nil)
      case "stop":
        self.status = "disconnected"
        self.eventSink?("macOS: stop requested")
        result(nil)
      case "status":
        result(self.status)
      case "trafficStats":
        if self.status == "connected" {
          self.rxBytes += 1024
          self.txBytes += 768
        }
        result(["rxBytes": self.rxBytes, "txBytes": self.txBytes])
      case "isBatteryOptimizationIgnored":
        result(true)
      case "requestDisableBatteryOptimization":
        result(nil)
      case "listInstalledApps":
        result(self.listMacInstalledApps())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let logsChannel = FlutterEventChannel(
      name: "unified_vpn/logs",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    logsChannel.setStreamHandler(MacLogStreamHandler(
      onListen: { sink in
        self.eventSink = sink
        sink("macOS: log stream connected")
      },
      onCancel: {
        self.eventSink = nil
      }
    ))

    super.awakeFromNib()
  }

  private func listMacInstalledApps() -> [[String: String]] {
    var pairs: [(String, String)] = []
    var seen = Set<String>()
    let bases = ["/Applications", "/System/Applications", "\(NSHomeDirectory())/Applications"]
    let fm = FileManager.default
    for base in bases {
      guard let urls = try? fm.contentsOfDirectory(
        at: URL(fileURLWithPath: base),
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      ) else {
        continue
      }
      for url in urls where url.pathExtension == "app" {
        guard let bundle = Bundle(url: url) else { continue }
        let bid = bundle.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        if !seen.insert(bid).inserted { continue }
        let name =
          (bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String)
          ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
          ?? (bundle.infoDictionary?["CFBundleName"] as? String)
          ?? url.deletingPathExtension().lastPathComponent
        pairs.append((bid, name))
      }
    }
    pairs.sort {
      $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending
    }
    return pairs.map { ["id": $0.0, "label": $0.1] }
  }
}

final class MacLogStreamHandler: NSObject, FlutterStreamHandler {
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
