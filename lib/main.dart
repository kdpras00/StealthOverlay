import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/window_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/hotkey_service.dart';
import 'ui/providers/overlay_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/overlay_screen.dart';
import 'core/models/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Filter out known Flutter framework debug assertion bugs for global hotkeys on macOS NSPanel
  FlutterError.onError = (FlutterErrorDetails details) {
    final bool isKeyboardAssertion = details.exception is AssertionError &&
        details.stack.toString().contains('hardware_keyboard.dart');
    if (isKeyboardAssertion) {
      return;
    }
    FlutterError.presentError(details);
  };

  // Handle unhandled async errors for hardware keyboard sync
  final originalOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is AssertionError && stack.toString().contains('hardware_keyboard.dart')) {
      return true;
    }
    return originalOnError != null ? originalOnError(error, stack) : false;
  };

  // Initialize Storage (Hive)
  await StorageService.initialize();

  // Initialize Desktop Overlay Window Properties
  await WindowService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => OverlayProvider(),
      child: const WhisperCueApp(),
    ),
  );
}

class WhisperCueApp extends StatefulWidget {
  const WhisperCueApp({super.key});

  @override
  State<WhisperCueApp> createState() => _WhisperCueAppState();
}

class _WhisperCueAppState extends State<WhisperCueApp> {
  @override
  void initState() {
    super.initState();
    _initHotkeys();
  }

  void _initHotkeys() {
    final provider = context.read<OverlayProvider>();
    HotkeyService.initialize(
      onPanicToggle: () {
        provider.togglePanicHide();
      },
      onStealthToggle: () {
        provider.toggleStealthMode();
      },
      onAnswerTrigger: () {
        provider.setMode(OverlayMode.answer);
        if (provider.currentTranscript.isNotEmpty) {
          provider.askAIQuestion(provider.currentTranscript);
        }
      },
      onScreenshotTrigger: () {
        provider.setMode(OverlayMode.screenshot);
      },
      onChatTrigger: () {
        provider.setMode(OverlayMode.chat);
      },
      onMicToggle: () {
        provider.toggleMicCapture();
      },
      onLockToggle: () {
        provider.toggleClickThrough();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhisperCue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OverlayScreen(),
    );
  }
}
