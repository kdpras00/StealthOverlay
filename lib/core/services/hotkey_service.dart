import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  static HotKey? _panicHotKey;
  static HotKey? _stealthHotKey;

  static Future<void> initialize({
    required VoidCallback onPanicToggle,
    required VoidCallback onStealthToggle,
  }) async {
    if (kIsWeb) return;

    try {
      await hotKeyManager.unregisterAll();

      bool isMac = Platform.isMacOS;

      _panicHotKey = HotKey(
        key: PhysicalKeyboardKey.keyH,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
          HotKeyModifier.shift,
        ],
        scope: HotKeyScope.system,
      );

      _stealthHotKey = HotKey(
        key: PhysicalKeyboardKey.keyS,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
          HotKeyModifier.shift,
        ],
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        _panicHotKey!,
        keyDownHandler: (hotKey) async {
          onPanicToggle();
        },
      );

      await hotKeyManager.register(
        _stealthHotKey!,
        keyDownHandler: (hotKey) async {
          onStealthToggle();
        },
      );
    } catch (e) {
      debugPrint('HotkeyService setup failed: $e');
    }
  }

  static String get panicShortcutText {
    if (kIsWeb) return 'Ctrl+Shift+H';
    return Platform.isMacOS ? '⌘+Shift+H' : 'Ctrl+Shift+H';
  }

  static String get stealthShortcutText {
    if (kIsWeb) return 'Ctrl+Shift+S';
    return Platform.isMacOS ? '⌘+Shift+S' : 'Ctrl+Shift+S';
  }
}
