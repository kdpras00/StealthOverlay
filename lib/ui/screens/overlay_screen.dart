import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/overlay_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/grid_overlay.dart';
import '../widgets/status_hud.dart';
import '../widgets/draggable_note.dart';
import '../widgets/stealth_warning_dialog.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayProvider>();

    if (provider.isPanicHidden) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Canvas Click Handler / Window Drag Area
          Positioned.fill(
            child: DragToMoveArea(
              child: Container(
                color: Colors.black.withValues(alpha: 0.01),
              ),
            ),
          ),

          // Optional Grid Canvas Background
          if (provider.showGrid) const GridOverlayWidget(),

          // Floating Notes Layer
          ...provider.notes.map((note) => DraggableNoteWidget(key: ValueKey(note.id), note: note)),

          // Floating Control Toolbar (Top Center)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: AppTheme.glassContainer(
                  color: const Color(0xFA1A1C23),
                  borderRadius: 24,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Window Handle
                    const DragToMoveArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.drag_handle_rounded, size: 20, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Stealth Mode Toggle
                    IconButton(
                      icon: Icon(
                        provider.isStealthEnabled ? Icons.visibility_off : Icons.visibility,
                        color: provider.isStealthEnabled ? AppTheme.stealthGreen : AppTheme.panicRed,
                      ),
                      tooltip: provider.isStealthEnabled
                          ? 'Stealth Mode Active (Screen Capture Protection ON)'
                          : 'Stealth Mode Off',
                      onPressed: () => provider.toggleStealthMode(),
                    ),

                    // Click-Through Lock Toggle
                    IconButton(
                      icon: Icon(
                        provider.isClickThrough ? Icons.lock : Icons.lock_open_outlined,
                        color: provider.isClickThrough ? AppTheme.warningOrange : AppTheme.textPrimary,
                      ),
                      tooltip: provider.isClickThrough ? 'Click-Through Active' : 'Enable Click-Through Mode',
                      onPressed: () => provider.toggleClickThrough(),
                    ),

                    // Grid Overlay Toggle Button
                    IconButton(
                      icon: Icon(
                        provider.showGrid ? Icons.grid_on : Icons.grid_off_outlined,
                        color: provider.showGrid ? AppTheme.accentColor : AppTheme.textSecondary,
                      ),
                      tooltip: provider.showGrid ? 'Hide Background Grid' : 'Show Alignment Grid',
                      onPressed: () => provider.toggleShowGrid(),
                    ),

                    // Add Note Button
                    IconButton(
                      icon: const Icon(Icons.note_add_outlined, color: AppTheme.accentColor),
                      tooltip: 'Add Floating Note',
                      onPressed: () => provider.addNote(),
                    ),

                    const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),

                    // Opacity Control Icon & Slider
                    const Icon(Icons.opacity, size: 18, color: AppTheme.textSecondary),
                    SizedBox(
                      width: 90,
                      child: Slider(
                        value: provider.opacity,
                        min: 0.2,
                        max: 1.0,
                        activeColor: AppTheme.accentColor,
                        onChanged: (val) => provider.setOpacity(val),
                      ),
                    ),

                    const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),

                    // macOS Sequoia Warning Button if applicable
                    if (provider.isMacOSSequoia)
                      IconButton(
                        icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange),
                        tooltip: 'macOS 15 Screen Capture Notice',
                        onPressed: () => StealthWarningDialog.show(context),
                      ),

                    // Panic Hide Button
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded, color: AppTheme.panicRed),
                      tooltip: 'Panic Hide Overlay',
                      onPressed: () => provider.togglePanicHide(),
                    ),

                    const SizedBox(width: 4),

                    // Close Window Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                      tooltip: 'Close Overlay',
                      onPressed: () => windowManager.close(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Status HUD
          const Positioned(
            bottom: 16,
            right: 16,
            child: StatusHud(),
          ),
        ],
      ),
    );
  }
}
