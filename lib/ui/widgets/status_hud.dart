import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/overlay_provider.dart';
import '../theme/app_theme.dart';
import '../../core/services/hotkey_service.dart';

class StatusHud extends StatelessWidget {
  const StatusHud({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayProvider>();
    final isStealth = provider.isStealthEnabled;
    final isClickThrough = provider.isClickThrough;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppTheme.glassContainer(
        color: const Color(0xEE1A1C23),
        borderRadius: 20,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stealth Mode Indicator Chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isStealth
                  ? AppTheme.stealthGreen.withValues(alpha: 0.2)
                  : AppTheme.panicRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isStealth ? AppTheme.stealthGreen : AppTheme.panicRed,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isStealth ? Icons.security : Icons.security_update_warning,
                  size: 14,
                  color: isStealth ? AppTheme.stealthGreen : AppTheme.panicRed,
                ),
                const SizedBox(width: 4),
                Text(
                  isStealth ? 'STEALTH ACTIVE' : 'STEALTH OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isStealth ? AppTheme.stealthGreen : AppTheme.panicRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Click-Through Status
          if (isClickThrough)
            Row(
              children: const [
                Icon(Icons.mouse, size: 14, color: AppTheme.warningOrange),
                SizedBox(width: 4),
                Text(
                  'CLICK-THROUGH ON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningOrange,
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),

          // Panic Hotkey Reminder
          Icon(Icons.keyboard, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Panic: ${HotkeyService.panicShortcutText}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
