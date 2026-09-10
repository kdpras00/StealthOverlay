import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  static HotKey? _panicHotKey;
  static HotKey? _stealthHotKey;
  static HotKey? _answerHotKey;
  static HotKey? _screenshotHotKey;
  static HotKey? _chatHotKey;
  static HotKey? _micHotKey;
  static HotKey? _lockHotKey;

  static Future<void> initialize({
    required VoidCallback onPanicToggle,
    required VoidCallback onStealthToggle,
    VoidCallback? onAnswerTrigger,
    VoidCallback? onScreenshotTrigger,
    VoidCallback? onChatTrigger,
    VoidCallback? onMicToggle,
    VoidCallback? onLockToggle,
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

      // ⌘+Enter → Trigger AI Answer
      _answerHotKey = HotKey(
        key: PhysicalKeyboardKey.enter,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
        ],
        scope: HotKeyScope.system,
      );

      // ⌘+Shift+C → Screenshot mode
      _screenshotHotKey = HotKey(
        key: PhysicalKeyboardKey.keyC,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
          HotKeyModifier.shift,
        ],
        scope: HotKeyScope.system,
      );

      // ⌘+K → Chat mode
      _chatHotKey = HotKey(
        key: PhysicalKeyboardKey.keyK,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
        ],
        scope: HotKeyScope.system,
      );

      // ⌘+Shift+M → Toggle mic
      _micHotKey = HotKey(
        key: PhysicalKeyboardKey.keyM,
        modifiers: [
          isMac ? HotKeyModifier.meta : HotKeyModifier.control,
          HotKeyModifier.shift,
        ],
        scope: HotKeyScope.system,
      );

      // ⌘+Shift+L → Toggle click-through lock
      _lockHotKey = HotKey(
        key: PhysicalKeyboardKey.keyL,
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

      if (onAnswerTrigger != null) {
        await hotKeyManager.register(
          _answerHotKey!,
          keyDownHandler: (hotKey) async {
            onAnswerTrigger();
          },
        );
      }

      if (onScreenshotTrigger != null) {
        await hotKeyManager.register(
          _screenshotHotKey!,
          keyDownHandler: (hotKey) async {
            onScreenshotTrigger();
          },
        );
      }

      if (onChatTrigger != null) {
        await hotKeyManager.register(
          _chatHotKey!,
          keyDownHandler: (hotKey) async {
            onChatTrigger();
          },
        );
      }

      if (onMicToggle != null) {
        await hotKeyManager.register(
          _micHotKey!,
          keyDownHandler: (hotKey) async {
            onMicToggle();
          },
        );
      }

      if (onLockToggle != null) {
        await hotKeyManager.register(
          _lockHotKey!,
          keyDownHandler: (hotKey) async {
            onLockToggle();
          },
        );
      }
    } catch (e) {
      debugPrint('HotkeyService setup failed: $e');
    }
  }

  static String get panicShortcutText {
    if (kIsWeb) return 'Ctrl+Shift+H';
    return Platform.isMacOS ? '⌘⇧H' : 'Ctrl+Shift+H';
  }

  static String get stealthShortcutText {
    if (kIsWeb) return 'Ctrl+Shift+S';
    return Platform.isMacOS ? '⌘⇧S' : 'Ctrl+Shift+S';
  }

  static String get answerShortcutText => Platform.isMacOS ? '⌘↵' : 'Ctrl+Enter';
  static String get screenshotShortcutText => Platform.isMacOS ? '⌘⇧C' : 'Ctrl+Shift+C';
  static String get chatShortcutText => Platform.isMacOS ? '⌘K' : 'Ctrl+K';
  static String get micShortcutText => Platform.isMacOS ? '⌘⇧M' : 'Ctrl+Shift+M';
  static String get lockShortcutText => Platform.isMacOS ? '⌘⇧L' : 'Ctrl+Shift+L';
}
