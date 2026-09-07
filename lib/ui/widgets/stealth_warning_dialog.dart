import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StealthWarningDialog extends StatelessWidget {
  const StealthWarningDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StealthWarningDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFA1F2128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.warningOrange, width: 1.5),
      ),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 24),
          SizedBox(width: 8),
          Text(
            'macOS 15+ Stealth Notice',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'On macOS 15 (Sequoia) and newer, ScreenCaptureKit prevents hardware window exclusion in certain desktop apps:\n',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
            Text(
              '⚠️ Screen Capture May Be Visible In:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
            ),
            SizedBox(height: 4),
            Text(
              '• Zoom Desktop Client\n'
              '• Microsoft Teams\n'
              '• QuickTime Player / Safari\n',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              '✅ Still Fully Invisible In:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.stealthGreen),
            ),
            SizedBox(height: 4),
            Text(
              '• Google Meet (Chrome & Firefox)\n'
              '• Windows 10/11 (All Screen Capture software)',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentColor,
          ),
          child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
