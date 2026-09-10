import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel wrapper for native system audio capture.
///
/// macOS: Uses ScreenCaptureKit (SCStream) for per-app audio capture.
/// Windows: Uses WASAPI loopback for system-wide audio capture.
///
/// The native layer captures PCM audio → converts to WAV chunks →
/// sends to Whisper API for transcription → returns text via EventChannel.
class NativeAudioService {
  static const MethodChannel _channel = MethodChannel('stealthai/audio');
  static const EventChannel _transcriptChannel =
      EventChannel('stealthai/audio/transcripts');

  static StreamSubscription? _subscription;
  static final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  /// Stream of transcribed text from native audio capture.
  static Stream<String> get transcriptStream => _transcriptController.stream;

  /// Whether native audio capture is currently active.
  static bool _isCapturing = false;
  static bool get isCapturing => _isCapturing;

  /// Start native system audio capture.
  ///
  /// On macOS, [targetApp] can specify a bundle identifier (e.g., "us.zoom.xos")
  /// to capture audio from a specific app. If null, captures all system audio.
  ///
  /// [apiKey] and [apiProvider] are passed to the native layer for Whisper STT.
  static Future<bool> startSystemCapture({
    String? targetApp,
    String apiKey = '',
    String apiProvider = 'groq',
    String lang = 'id-ID',
  }) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startSystemAudioCapture', {
        'targetApp': targetApp,
        'apiKey': apiKey,
        'apiProvider': apiProvider,
        'lang': lang,
      });

      if (result == true) {
        _isCapturing = true;
        _listenForTranscripts();
      }

      return result ?? false;
    } on MissingPluginException {
      debugPrint('[NativeAudio] Platform channel not implemented');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[NativeAudio] Failed to start: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[NativeAudio] Unexpected error: $e');
      return false;
    }
  }

  /// Stop native system audio capture.
  static Future<void> stopSystemCapture() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stopSystemAudioCapture');
    } catch (_) {}
    _isCapturing = false;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Start capturing audio from the hardware microphone.
  /// Transcripts arrive via the same [transcriptStream].
  static Future<bool> startMicCapture({
    String apiKey = '',
    String apiProvider = 'groq',
    String lang = 'id-ID',
  }) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startMicCapture', {
        'apiKey': apiKey,
        'apiProvider': apiProvider,
        'lang': lang,
      });

      if (result == true) {
        _isMicActive = true;
        _listenForTranscripts();
      }

      return result ?? false;
    } on MissingPluginException {
      debugPrint('[NativeAudio] Mic capture not implemented on this platform');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[NativeAudio] Failed to start mic: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[NativeAudio] Unexpected mic error: $e');
      return false;
    }
  }

  /// Stop mic capture.
  static Future<void> stopMicCapture() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stopMicCapture');
    } catch (_) {}
    _isMicActive = false;
  }

  /// Whether native mic capture is currently active.
  static bool _isMicActive = false;
  static bool get isMicActive => _isMicActive;

  /// List available audio sources (running apps with audio output).
  /// Returns list of app names or bundle identifiers.
  static Future<List<String>> listAudioSources() async {
    if (kIsWeb) return [];
    try {
      final result = await _channel.invokeMethod<List>('listAudioSources');
      return result?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('[NativeAudio] Failed to list sources: $e');
      return [];
    }
  }

  /// Listen for transcript events from the native EventChannel.
  static void _listenForTranscripts() {
    _subscription?.cancel();
    _subscription = _transcriptChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
            if (event is String && event.isNotEmpty) {
              _transcriptController.add(event);
            }
          },
          onError: (error) {
            debugPrint('[NativeAudio] Transcript stream error: $error');
          },
        );
  }

  /// Dispose of resources.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _transcriptController.close();
  }
}
