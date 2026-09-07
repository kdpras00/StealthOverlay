import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSPanel {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Configure panel properties to float above Chrome without stealing app focus or switching spaces
    self.styleMask.insert(.nonactivatingPanel)
    self.becomesKeyOnlyIfNeeded = true
    self.hidesOnDeactivate = false
    self.isMovableByWindowBackground = true
    self.level = .statusBar
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

    RegisterGeneratedPlugins(registry: flutterViewController)

    setupStealthChannel(controller: flutterViewController)

    super.awakeFromNib()
  }

  private func setupStealthChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: "stealthai/window", binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Window unavailable", details: nil))
        return
      }

      switch call.method {
      case "enableStealthMode":
        if #available(macOS 10.15, *) {
          self.sharingType = .none
        }
        result(true)

      case "disableStealthMode":
        if #available(macOS 10.15, *) {
          self.sharingType = .readOnly
        }
        result(true)

      case "isMacOSSequoiaOrLater":
        if #available(macOS 15.0, *) {
          result(true)
        } else {
          result(false)
        }

      case "isStealthEnabled":
        if #available(macOS 10.15, *) {
          result(self.sharingType == .none)
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
