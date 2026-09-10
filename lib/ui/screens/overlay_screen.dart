import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/models/settings.dart';
import '../../core/services/hotkey_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/pdf_service.dart';
import '../providers/overlay_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/grid_overlay.dart';
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
          if (provider.showGrid && !provider.isMinimized) const GridOverlayWidget(),

          // Floating Notes Layer (hidden when minimized)
          if (!provider.isMinimized)
            ...provider.notes.map((note) => DraggableNoteWidget(key: ValueKey(note.id), note: note)),

          // ── Main UI Layout (Top Bar -> Live Transcript -> AI Answer stacked vertically) ──
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Header Control Toolbar
                  Center(
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
                            tooltip: provider.isClickThrough
                                ? 'Click-Through Active (${HotkeyService.lockShortcutText})'
                                : 'Enable Click-Through Mode (${HotkeyService.lockShortcutText})',
                            onPressed: () => provider.toggleClickThrough(),
                          ),

                          if (!provider.isMinimized) ...[
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
                          ],

                          // 🎤 Mic Capture Toggle
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: Icon(
                                  provider.isMicActive ? Icons.mic : Icons.mic_off_outlined,
                                  color: provider.isMicActive ? const Color(0xFF4ADE80) : AppTheme.textSecondary,
                                ),
                                tooltip: provider.isMicActive ? 'Mic Active (click to stop)' : 'Start Mic Capture',
                                onPressed: () => provider.toggleMicCapture(),
                              ),
                              if (provider.isMicActive)
                                const Positioned(top: 8, right: 8, child: _AudioPulseDot(color: Color(0xFF4ADE80))),
                            ],
                          ),

                          // 🔊 System Audio Capture Toggle
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: Icon(
                                  provider.isSystemAudioActive ? Icons.surround_sound : Icons.surround_sound_outlined,
                                  color: provider.isSystemAudioActive ? const Color(0xFF60A5FA) : AppTheme.textSecondary,
                                ),
                                tooltip: provider.isSystemAudioActive ? 'System Audio Active (click to stop)' : 'Start System Audio Capture',
                                onPressed: () => provider.toggleSystemAudioCapture(),
                              ),
                              if (provider.isSystemAudioActive)
                                const Positioned(top: 8, right: 8, child: _AudioPulseDot(color: Color(0xFF60A5FA))),
                            ],
                          ),

                          if (!provider.isMinimized) ...[
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

                            // Language Toggle (ID ↔ EN)
                            GestureDetector(
                              onTap: () => provider.toggleLanguage(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  provider.speechLang == 'id-ID' ? 'ID' : 'EN',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB)),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Mode Pills (Answer / Screenshot / Chat)
                            _ModePill(label: 'Answer', shortcut: '⌘↵', isActive: provider.currentMode == OverlayMode.answer, onTap: () => provider.setMode(OverlayMode.answer)),
                            _ModePill(label: 'Screenshot', shortcut: '⌘⇧C', isActive: provider.currentMode == OverlayMode.screenshot, onTap: () => provider.setMode(OverlayMode.screenshot)),
                            _ModePill(label: 'Chat', shortcut: '⌘K', isActive: provider.currentMode == OverlayMode.chat, onTap: () => provider.setMode(OverlayMode.chat)),

                            const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),

                            // Settings Gear
                            IconButton(
                              icon: Icon(
                                Icons.settings_outlined,
                                color: provider.showSettingsPanel ? AppTheme.accentColor : AppTheme.textSecondary,
                                size: 18,
                              ),
                              tooltip: 'Settings',
                              onPressed: () => provider.toggleSettingsPanel(),
                            ),
                          ] else ...[
                            const SizedBox(width: 6),
                            const Text(
                              '(Minimized)',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Minimize / Expand Toggle Button
                          IconButton(
                            icon: Icon(
                              provider.isMinimized ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                              color: provider.isMinimized ? AppTheme.accentColor : AppTheme.textSecondary,
                              size: 18,
                            ),
                            tooltip: provider.isMinimized ? 'Expand Overlay' : 'Minimize Overlay',
                            onPressed: () => provider.toggleMinimize(),
                          ),

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

                  // 2. Live Transcript Bar (SEPARATE card, auto-expands downward to fit voice text!)
                  if (provider.currentTranscript.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: _LiveTranscriptBar(provider: provider),
                    ),
                  ],

                  // 3. AI Answer Card (SEPARATE card, auto-expands downward below transcript!)
                  if (provider.aiAnswer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: _AIAnswerCard(provider: provider),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Settings Panel (shown when settings gear is clicked) ──
          if (provider.showSettingsPanel && !provider.isMinimized)
            Positioned(
              top: 56,
              right: 16,
              child: _SettingsPanel(provider: provider),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE TRANSCRIPT BAR — Word Chips + Audio Source Indicator
// ═══════════════════════════════════════════════════════════════════════════
class _LiveTranscriptBar extends StatefulWidget {
  final OverlayProvider provider;
  const _LiveTranscriptBar({required this.provider});

  @override
  State<_LiveTranscriptBar> createState() => _LiveTranscriptBarState();
}

class _LiveTranscriptBarState extends State<_LiveTranscriptBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _LiveTranscriptBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.currentTranscript != oldWidget.provider.currentTranscript) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcript = widget.provider.currentTranscript;
    final source = widget.provider.activeSource;

    if (transcript.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.glassContainer(
        color: const Color(0xF713151B),
        borderRadius: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio source badge & icon
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x2010B981),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x4010B981)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    source == AudioSource.system
                        ? Icons.surround_sound
                        : source == AudioSource.tab
                            ? Icons.tab
                            : Icons.mic,
                    size: 13,
                    color: AppTheme.stealthGreen,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.stealthGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Speech text wrapping vertically downwards (kebawah)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                transcript,
                style: const TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Clear button
          GestureDetector(
            onTap: () => widget.provider.clearTranscripts(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI ANSWER CARD — Streaming response with copy button
// ═══════════════════════════════════════════════════════════════════════════
class _AIAnswerCard extends StatelessWidget {
  final OverlayProvider provider;
  const _AIAnswerCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final answer = provider.aiAnswer;
    final isGenerating = provider.isAiGenerating;

    if (answer.isEmpty && !isGenerating) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 420),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassContainer(
        color: const Color(0xF7141519),
        borderRadius: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppTheme.stealthGreen),
              const SizedBox(width: 6),
              Text(
                isGenerating
                    ? '✨ AI Generating Answer...'
                    : (provider.hasPendingAiTimer
                        ? '👂 Listening (waiting for speaker to finish...)'
                        : 'AI Answer'),
                style: TextStyle(
                  color: provider.hasPendingAiTimer ? const Color(0xFF6EE7B7) : const Color(0xFFF3F4F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isGenerating)
                GestureDetector(
                  onTap: () => provider.stopAIGeneration(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.panicRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.panicRed.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 12, color: AppTheme.panicRed),
                        SizedBox(width: 4),
                        Text('Stop', style: TextStyle(color: AppTheme.panicRed, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              if (!isGenerating && provider.currentTranscript.isNotEmpty)
                GestureDetector(
                  onTap: () => provider.regenerateAIAnswer(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 12, color: Color(0xFF60A5FA)),
                        SizedBox(width: 4),
                        Text('Re-ask', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              if (answer.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: answer));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 12, color: Color(0xFFD1D5DB)),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => provider.clearAIAnswer(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Answer Content
          if (answer.isNotEmpty)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FormattedMarkdownText(
                  text: answer,
                  baseStyle: const TextStyle(
                    color: Color(0xFFF9FAFB),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ),
            ),

          // Generating indicator bar
          if (isGenerating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.stealthGreen)),
                      ),
                      SizedBox(width: 8),
                      Text('Thinking & streaming AI response...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.stealthGreen),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODE PILL — Answer / Screenshot / Chat mode selector
// ═══════════════════════════════════════════════════════════════════════════
class _ModePill extends StatelessWidget {
  final String label;
  final String shortcut;
  final bool isActive;
  final VoidCallback onTap;

  const _ModePill({required this.label, required this.shortcut, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppTheme.accentColor.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.accentColor : const Color(0xFFD1D5DB),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                shortcut,
                style: TextStyle(
                  color: (isActive ? AppTheme.accentColor : const Color(0xFF9CA3AF)).withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS PANEL — API key, provider, model, system prompt
// ═══════════════════════════════════════════════════════════════════════════
class _SettingsPanel extends StatefulWidget {
  final OverlayProvider provider;
  const _SettingsPanel({required this.provider});

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _customModelCtrl = TextEditingController();
  final TextEditingController _profileCtrl = TextEditingController();
  String _selectedProvider = 'groq';
  String _selectedModel = 'auto';
  bool _obscureApiKey = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl.text = widget.provider.apiKey;
    _profileCtrl.text = widget.provider.userProfile;
    _selectedProvider = widget.provider.apiProvider;
    final currentModel = widget.provider.aiModel;

    _customModelCtrl.text = currentModel == 'auto' ? '' : currentModel;
    _selectedModel = _resolveInitialModelValue(_selectedProvider, currentModel);
  }

  String _resolveInitialModelValue(String provider, String model) {
    if (model.isEmpty || model == 'auto') return 'auto';
    final presets = LlmService.providerModels[provider] ?? [];
    if (presets.any((m) => m['id'] == model)) {
      return model;
    }
    return 'custom';
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _customModelCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdfResume() async {
    final text = await PdfService.pickAndExtractPdfText();
    if (text != null && text.isNotEmpty && mounted) {
      setState(() {
        _profileCtrl.text = text;
      });
    }
  }

  void _saveSettings() {
    final finalModel = _selectedModel == 'custom'
        ? _customModelCtrl.text.trim()
        : _selectedModel;

    widget.provider.updateApiSettings(
      apiKey: _apiKeyCtrl.text.trim(),
      apiProvider: _selectedProvider,
      aiModel: finalModel,
      userProfile: _profileCtrl.text.trim(),
    );

    setState(() {
      _isSaved = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.provider.toggleSettingsPanel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final providers = ['groq', 'openai', 'gemini', 'anthropic', 'ollama'];
    final presetModels = LlmService.providerModels[_selectedProvider] ?? [];

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassContainer(
        color: const Color(0xFA141519),
        borderRadius: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header (outside scroll area so X is ALWAYS clickable)
          Row(
            children: [
              const Icon(Icons.settings, size: 15, color: AppTheme.accentColor),
              const SizedBox(width: 6),
              const Text('Settings', style: TextStyle(color: Color(0xFFF3F4F6), fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.provider.toggleSettingsPanel(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Body with Transparent Scrollbar Behavior
          Flexible(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // API Key
                    _settingsLabel('API Key'),
                    _settingsTextField(
                      _apiKeyCtrl,
                      'gsk_... / sk-... / AIza...',
                      obscure: _obscureApiKey,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                            size: 16,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Provider
                    _settingsLabel('Provider'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedProvider,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1C23),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
                        items: providers.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedProvider = v;
                              _selectedModel = 'auto';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Model Selection (Per-provider Dropdown)
                    _settingsLabel('AI Model'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedModel,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1C23),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
                        items: [
                          const DropdownMenuItem(value: 'auto', child: Text('✨ Auto (Default Recommended)')),
                          ...presetModels.map((m) => DropdownMenuItem(
                                value: m['id']!,
                                child: Text(m['name']!, overflow: TextOverflow.ellipsis),
                              )),
                          const DropdownMenuItem(value: 'custom', child: Text('✏️ Custom Model ID...')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedModel = v;
                            });
                          }
                        },
                      ),
                    ),

                    if (_selectedModel == 'custom') ...[
                      const SizedBox(height: 6),
                      _settingsTextField(_customModelCtrl, 'Enter model ID (e.g. gpt-4o)'),
                    ],

                    const SizedBox(height: 10),

                    // Speech Language
                    _settingsLabel('Speech Language'),
                    Row(
                      children: [
                        _langChip('Indonesia', 'id-ID'),
                        const SizedBox(width: 8),
                        _langChip('English', 'en-US'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Candidate Profile / Resume Context
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _settingsLabel('Candidate Profile / Resume Context'),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _pickPdfResume,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload_file, size: 12, color: Color(0xFF6EE7B7)),
                                  SizedBox(width: 4),
                                  Text('Upload PDF/TXT', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _settingsTextField(_profileCtrl, 'Uploaded resume PDF text will automatically adapt AI answers...', maxLines: 4),
                    const SizedBox(height: 14),

                    // Keyboard shortcuts reference
                    _settingsLabel('Keyboard Shortcuts'),
                    _shortcutRow('Panic Hide', HotkeyService.panicShortcutText),
                    _shortcutRow('Stealth Mode', HotkeyService.stealthShortcutText),
                    _shortcutRow('Toggle Lock', HotkeyService.lockShortcutText),
                    _shortcutRow('AI Answer', HotkeyService.answerShortcutText),
                    _shortcutRow('Screenshot', HotkeyService.screenshotShortcutText),
                    _shortcutRow('Chat Mode', HotkeyService.chatShortcutText),
                    _shortcutRow('Toggle Mic', HotkeyService.micShortcutText),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fixed Action Buttons
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _saveSettings,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSaved ? const Color(0xFF10B981) : AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSaved ? Icons.check_circle : Icons.save, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _isSaved ? 'Saved!' : 'Save Settings',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.provider.toggleSettingsPanel(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _settingsTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    int maxLines = 1,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
    );
  }



  Widget _langChip(String label, String langCode) {
    final isActive = widget.provider.speechLang == langCode;
    return GestureDetector(
      onTap: () {
        if (!isActive) widget.provider.toggleLanguage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppTheme.accentColor : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isActive ? AppTheme.accentColor : const Color(0xFFD1D5DB), fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _shortcutRow(String action, String keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(keys, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontFamily: 'Menlo')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FORMATTED MARKDOWN TEXT — Renders bold, italic, code, bullets & headings
// ═══════════════════════════════════════════════════════════════════════════
class FormattedMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const FormattedMarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final defaultStyle = baseStyle ??
        const TextStyle(
          color: Color(0xFFF9FAFB),
          fontSize: 12.5,
          height: 1.55,
        );

    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        lineWidgets.add(const SizedBox(height: 6));
        continue;
      }

      final leadingSpaces = line.length - line.trimLeft().length;
      final isSubBullet = leadingSpaces >= 2;
      final isBullet = trimmed.startsWith('- ') || trimmed.startsWith('* ') || RegExp(r'^\d+\.\s').hasMatch(trimmed);

      String content = trimmed;
      Widget prefixWidget = const SizedBox.shrink();

      if (trimmed.startsWith('# ')) {
        content = trimmed.substring(2);
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: _buildRichText(
              content,
              defaultStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF60A5FA),
              ),
            ),
          ),
        );
        continue;
      } else if (trimmed.startsWith('## ')) {
        content = trimmed.substring(3);
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 3),
            child: _buildRichText(
              content,
              defaultStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF93C5FD),
              ),
            ),
          ),
        );
        continue;
      } else if (trimmed.startsWith('### ')) {
        content = trimmed.substring(4);
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: _buildRichText(
              content,
              defaultStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6EE7B7),
              ),
            ),
          ),
        );
        continue;
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        content = trimmed.substring(2);
        prefixWidget = Padding(
          padding: EdgeInsets.only(right: 6, top: isSubBullet ? 2 : 0),
          child: Text(
            isSubBullet ? '◦' : '•',
            style: TextStyle(
              color: isSubBullet ? const Color(0xFF9CA3AF) : AppTheme.stealthGreen,
              fontSize: isSubBullet ? 10 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+\.)\s').firstMatch(trimmed);
        if (match != null) {
          final numPrefix = match.group(1)!;
          content = trimmed.substring(match.end);
          prefixWidget = Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              numPrefix,
              style: const TextStyle(
                color: AppTheme.stealthGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }

      lineWidgets.add(
        Padding(
          padding: EdgeInsets.only(
            left: isSubBullet ? 16.0 : (isBullet ? 4.0 : 0.0),
            bottom: 3.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet) prefixWidget,
              Expanded(
                child: _buildRichText(content, defaultStyle),
              ),
            ],
          ),
        ),
      );
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lineWidgets,
      ),
    );
  }

  /// Parses inline markdown formatting (**bold**, *italic*, `code`) into TextSpans.
  Widget _buildRichText(String text, TextStyle defaultStyle) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'(\*\*(.*?)\*\*|\*(.*?)\*|`(.*?)`)');
    int lastEnd = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: defaultStyle));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        final boldContent = match.group(2) ?? '';
        spans.add(
          TextSpan(
            text: boldContent,
            style: defaultStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        final italicContent = match.group(3) ?? '';
        spans.add(
          TextSpan(
            text: italicContent,
            style: defaultStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        );
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final codeContent = match.group(4) ?? '';
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12, width: 0.5),
              ),
              child: Text(
                codeContent,
                style: defaultStyle.copyWith(
                  fontFamily: 'monospace',
                  fontSize: defaultStyle.fontSize != null ? defaultStyle.fontSize! * 0.9 : 11,
                  color: AppTheme.stealthGreen,
                ),
              ),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    return Text.rich(
      TextSpan(children: spans, style: defaultStyle),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUDIO PULSE DOT — Animated indicator for active audio capture
// ═══════════════════════════════════════════════════════════════════════════
class _AudioPulseDot extends StatefulWidget {
  final Color color;
  const _AudioPulseDot({required this.color});

  @override
  State<_AudioPulseDot> createState() => _AudioPulseDotState();
}

class _AudioPulseDotState extends State<_AudioPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}
