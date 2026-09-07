import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/window_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/hotkey_service.dart';
import 'ui/providers/overlay_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/overlay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage (Hive)
  await StorageService.initialize();

  // Initialize Desktop Overlay Window Properties
  await WindowService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => OverlayProvider(),
      child: const StealthOverlayApp(),
    ),
  );
}

class StealthOverlayApp extends StatefulWidget {
  const StealthOverlayApp({super.key});

  @override
  State<StealthOverlayApp> createState() => _StealthOverlayAppState();
}

class _StealthOverlayAppState extends State<StealthOverlayApp> {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stealth Overlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OverlayScreen(),
    );
  }
}
