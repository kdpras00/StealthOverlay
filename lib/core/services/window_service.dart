import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await windowManager.ensureInitialized();

      await Window.initialize();
      if (Platform.isWindows) {
        await Window.setEffect(effect: WindowEffect.acrylic, color: const Color(0x1A000000));
      } else if (Platform.isMacOS) {
        await Window.makeTitlebarTransparent();
        await Window.enableFullSizeContentView();
      }

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1100, 750),
        minimumSize: Size(400, 300),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setAsFrameless();
        await windowManager.setBackgroundColor(Colors.transparent);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    if (kIsWeb) return;
    try {
      await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    } catch (_) {}
  }

  static Future<void> setIgnoreMouseEvents(bool ignore, {bool forward = false}) async {
    if (kIsWeb) return;
    try {
      await windowManager.setIgnoreMouseEvents(ignore, forward: forward);
    } catch (_) {}
  }

  static Future<void> setOpacity(double opacity) async {
    if (kIsWeb) return;
    try {
      await windowManager.setOpacity(opacity.clamp(0.1, 1.0));
    } catch (_) {}
  }

  static Future<void> hideWindow() async {
    if (kIsWeb) return;
    try {
      await windowManager.hide();
    } catch (_) {}
  }

  static Future<void> showWindow() async {
    if (kIsWeb) return;
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  static Future<bool> isVisible() async {
    if (kIsWeb) return true;
    try {
      return await windowManager.isVisible();
    } catch (_) {
      return true;
    }
  }
}
