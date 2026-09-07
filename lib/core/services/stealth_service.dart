import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StealthService {
  static const MethodChannel _channel = MethodChannel('stealthai/window');

  static Future<bool> enableStealthMode() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('enableStealthMode');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Failed to enable stealth mode: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error enabling stealth mode: $e');
      return false;
    }
  }

  static Future<bool> disableStealthMode() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('disableStealthMode');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Failed to disable stealth mode: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error disabling stealth mode: $e');
      return false;
    }
  }

  static Future<bool> isMacOSSequoiaOrLater() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isMacOSSequoiaOrLater');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isStealthEnabled() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isStealthEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
