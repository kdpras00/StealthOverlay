import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSPanel {
  private var audioCaptureHelper: Any? = nil // AudioCaptureHelper (macOS 12.3+)
  private var audioTranscriptSink: FlutterEventSink? = nil

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
    if #available(macOS 10.15, *) {
      self.sharingType = .none
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    setupStealthChannel(controller: flutterViewController)
    setupAudioChannel(controller: flutterViewController)

    super.awakeFromNib()
  }

  // MARK: - Stealth Mode Channel

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

  // MARK: - Audio Capture Channel

  private func setupAudioChannel(controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: "stealthai/audio",
      binaryMessenger: controller.engine.binaryMessenger
    )

    let eventChannel = FlutterEventChannel(
      name: "stealthai/audio/transcripts",
      binaryMessenger: controller.engine.binaryMessenger
    )

    // Event channel for streaming transcripts
    let streamHandler = AudioTranscriptStreamHandler()
    eventChannel.setStreamHandler(streamHandler)

    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Window unavailable", details: nil))
        return
      }

      switch call.method {
      case "startSystemAudioCapture":
        if #available(macOS 13.0, *) {
          let args = call.arguments as? [String: Any] ?? [:]
          let targetApp = args["targetApp"] as? String
          let apiKey = args["apiKey"] as? String ?? ""
          let apiProvider = args["apiProvider"] as? String ?? "groq"
          let lang = args["lang"] as? String ?? "id-ID"

          Task {
            do {
              let helper = AudioCaptureHelper()
              helper.onTranscript = { text in
                streamHandler.send(text)
              }
              try await helper.startCapture(
                targetAppBundleId: targetApp,
                apiKey: apiKey,
                apiProvider: apiProvider,
                lang: lang
              )
              self.audioCaptureHelper = helper
              DispatchQueue.main.async {
                result(true)
              }
            } catch {
              DispatchQueue.main.async {
                result(FlutterError(
                  code: "CAPTURE_ERROR",
                  message: error.localizedDescription,
                  details: nil
                ))
              }
            }
          }
        } else {
          result(FlutterError(
            code: "UNSUPPORTED",
            message: "System audio capture requires macOS 13.0+",
            details: nil
          ))
        }

      case "stopSystemAudioCapture":
        if #available(macOS 13.0, *) {
          if let helper = self.audioCaptureHelper as? AudioCaptureHelper {
            Task {
              await helper.stopCapture()
              self.audioCaptureHelper = nil
              DispatchQueue.main.async {
                result(true)
              }
            }
          } else {
            result(true)
          }
        } else {
          result(true)
        }

      case "listAudioSources":
        if #available(macOS 13.0, *) {
          Task {
            let sources = await AudioCaptureHelper.listAudioSources()
            DispatchQueue.main.async {
              result(sources)
            }
          }
        } else {
          result([String]())
        }

      case "startMicCapture":
        if #available(macOS 13.0, *) {
          let args = call.arguments as? [String: Any] ?? [:]
          let apiKey = args["apiKey"] as? String ?? ""
          let apiProvider = args["apiProvider"] as? String ?? "groq"
          let lang = args["lang"] as? String ?? "id-ID"

          do {
            // Reuse existing helper or create new one
            let helper: AudioCaptureHelper
            if let existing = self.audioCaptureHelper as? AudioCaptureHelper {
              helper = existing
            } else {
              helper = AudioCaptureHelper()
              helper.onTranscript = { text in
                streamHandler.send(text)
              }
              self.audioCaptureHelper = helper
            }
            try helper.startMicCapture(apiKey: apiKey, apiProvider: apiProvider, lang: lang)
            result(true)
          } catch {
            result(FlutterError(
              code: "MIC_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        } else {
          result(FlutterError(
            code: "UNSUPPORTED",
            message: "Mic capture requires macOS 13.0+",
            details: nil
          ))
        }

      case "stopMicCapture":
        if #available(macOS 13.0, *) {
          if let helper = self.audioCaptureHelper as? AudioCaptureHelper {
            helper.stopMicCapture()
          }
          result(true)
        } else {
          result(true)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// MARK: - Event Channel Stream Handler

class AudioTranscriptStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  func send(_ transcript: String) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(transcript)
    }
  }
}
