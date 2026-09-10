import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/sticky_note.dart';
import '../../core/models/settings.dart';
import '../../core/services/stealth_service.dart';
import '../../core/services/window_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/browser_bridge_service.dart';
import '../../core/services/websocket_bridge_service.dart';
import '../../core/services/transcript_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/native_audio_service.dart';

class OverlayProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  List<StickyNote> _notes = [];
  bool _isPanicHidden = false;
  bool _isMacOSSequoia = false;
  final BrowserBridgeService _browserBridge = BrowserBridgeService();
  final WebSocketBridgeService _wsBridge = WebSocketBridgeService();
  late final LlmService _llm;
  late final TranscriptService _transcript;
  bool _isMicActive = false;
  bool _isSystemAudioActive = false;

  AppSettings get settings => _settings;
  List<StickyNote> get notes => _notes;
  bool get isPanicHidden => _isPanicHidden;
  bool get isMacOSSequoia => _isMacOSSequoia;
  bool get isStealthEnabled => _settings.stealthEnabled;
  bool get isClickThrough => _settings.clickThrough;
  bool get showGrid => _settings.showGrid;
  double get opacity => _settings.opacity;

  // ── Voice / Transcript / AI getters ──
  TranscriptService get transcript => _transcript;
  List<String> get wordChips => _transcript.wordChips;
  String get currentTranscript => _transcript.currentTranscript;
  String get aiAnswer => _transcript.aiAnswer;
  bool get isAiGenerating => _transcript.isAiGenerating;
  bool get hasPendingAiTimer => _transcript.hasPendingAiTimer;
  bool get isListening => _transcript.isListening;
  AudioSource get activeSource => _transcript.activeSource;
  bool get isWsConnected => _wsBridge.isRunning;
  bool get isMicActive => _isMicActive;
  bool get isSystemAudioActive => _isSystemAudioActive;

  // ── Mode / Minimize / Settings ──
  OverlayMode _currentMode = OverlayMode.answer;
  bool _showSettingsPanel = false;
  OverlayMode get currentMode => _currentMode;
  bool get isMinimized => _settings.isMinimized;
  bool get showSettingsPanel => _showSettingsPanel;
  String get systemPrompt => _settings.systemPrompt;
  String get userProfile => _settings.userProfile;
  String get speechLang => _settings.speechLang;
  String get apiKey => _settings.apiKey;
  String get apiProvider => _settings.apiProvider;
  String get aiModel => _settings.aiModel;

  OverlayProvider() {
    _llm = LlmService();
    _transcript = TranscriptService(llm: _llm);
    _transcript.addListener(_onTranscriptChanged);
    _init();
  }

  Future<void> _init() async {
    _settings = StorageService.loadSettings();
    // Always default to unlocked (clickThrough = false) on startup
    _settings.clickThrough = false;
    await StorageService.saveSettings(_settings);
    _notes = StorageService.loadNotes();
    // Remove welcome note if previously stored
    if (_notes.any((n) => n.id == 'welcome_note')) {
      _notes.removeWhere((n) => n.id == 'welcome_note');
      await StorageService.deleteNote('welcome_note');
    }

    _isMacOSSequoia = await StealthService.isMacOSSequoiaOrLater();

    // Configure LLM from saved settings
    _llm.updateConfig(
      apiKey: _settings.apiKey,
      provider: LlmService.parseProvider(_settings.apiProvider),
      baseUrl: _settings.apiBaseUrl,
      model: _settings.aiModel,
      userProfile: _settings.userProfile,
    );

    // Sync native window state
    await _applyNativeSettings();

    // Start browser bridge (HTTP)
    await _browserBridge.start(
      port: _settings.serverPort,
      initialVisible: !_isPanicHidden,
      onNoteReceived: (title, content) {
        addNote(title: title, content: content);
      },
      onVisibilityToggled: (visible) {
        setOverlayVisibility(visible);
      },
      onTranscriptReceived: (text, source, lang) {
        final audioSource = source.contains('tab') ? AudioSource.tab : AudioSource.mic;
        _handleIncomingTranscript(text, audioSource, lang: lang);
      },
    );

    // Start WebSocket bridge
    await _wsBridge.start(
      port: 8766,
      onTranscript: (text, source, lang) {
        final audioSource = source.contains('tab')
            ? AudioSource.tab
            : source.contains('system')
                ? AudioSource.system
                : AudioSource.mic;
        _handleIncomingTranscript(text, audioSource, lang: lang);
      },
      onChat: (question) {
        _transcript.askQuestion(question);
      },
    );

    notifyListeners();
  }

  void _handleIncomingTranscript(String text, AudioSource source, {String? lang}) {
    _transcript.addTranscript(text, source, lang: lang ?? _settings.speechLang, autoTriggerAI: true);
    _updateWindowSizeForState();
  }

  double _lastTargetHeight = 0;

  void _onTranscriptChanged() {
    _updateWindowSizeForState();
    notifyListeners();
  }

  Future<void> _updateWindowSizeForState() async {
    final double targetHeight;

    if (_settings.isMinimized) {
      if (_transcript.aiAnswer.isNotEmpty || _transcript.currentTranscript.isNotEmpty) {
        targetHeight = 550;
      } else {
        targetHeight = 60;
      }
    } else {
      targetHeight = 750;
    }

    if (_lastTargetHeight != targetHeight) {
      _lastTargetHeight = targetHeight;
      await WindowService.setWindowSize(1100, targetHeight);
    }
  }

  // ── API Settings ──

  Future<void> updateApiSettings({
    String? apiKey,
    String? apiProvider,
    String? apiBaseUrl,
    String? aiModel,
    String? userProfile,
  }) async {
    if (apiKey != null) _settings.apiKey = apiKey;
    if (apiProvider != null) _settings.apiProvider = apiProvider;
    if (apiBaseUrl != null) _settings.apiBaseUrl = apiBaseUrl;
    if (aiModel != null) _settings.aiModel = aiModel;
    if (userProfile != null) _settings.userProfile = userProfile;

    _llm.updateConfig(
      apiKey: _settings.apiKey,
      provider: LlmService.parseProvider(_settings.apiProvider),
      baseUrl: _settings.apiBaseUrl,
      model: _settings.aiModel,
      userProfile: _settings.userProfile,
    );

    await StorageService.saveSettings(_settings);
    notifyListeners();
  }

  // ── Voice Controls ──

  void askAIQuestion(String question) {
    _transcript.askQuestion(question);
    _updateWindowSizeForState();
  }

  void clearTranscripts() {
    _transcript.clearTranscripts();
    _updateWindowSizeForState();
  }

  void stopAIGeneration() {
    _transcript.stopAIGeneration();
    _updateWindowSizeForState();
  }

  void regenerateAIAnswer() {
    _transcript.regenerateAIAnswer();
    _updateWindowSizeForState();
  }

  void clearAIAnswer() {
    _transcript.clearAIAnswer();
    _updateWindowSizeForState();
  }

  /// Toggle native mic capture on/off.
  Future<void> toggleMicCapture() async {
    if (_isMicActive) {
      await NativeAudioService.stopMicCapture();
      _isMicActive = false;
    } else {
      final success = await NativeAudioService.startMicCapture(
        apiKey: _settings.apiKey,
        apiProvider: _settings.apiProvider,
        lang: _settings.speechLang,
      );
      _isMicActive = success;
      if (success) {
        _transcript.setListening(true);
        // Listen for native transcripts
        NativeAudioService.transcriptStream.listen((text) {
          _handleIncomingTranscript(text, AudioSource.mic, lang: _settings.speechLang);
        });
      }
    }
    notifyListeners();
  }

  /// Toggle native system audio capture on/off.
  Future<void> toggleSystemAudioCapture({String? targetApp}) async {
    if (_isSystemAudioActive) {
      await NativeAudioService.stopSystemCapture();
      _isSystemAudioActive = false;
    } else {
      final success = await NativeAudioService.startSystemCapture(
        targetApp: targetApp,
        apiKey: _settings.apiKey,
        apiProvider: _settings.apiProvider,
        lang: _settings.speechLang,
      );
      _isSystemAudioActive = success;
      if (success) {
        _transcript.setListening(true);
        NativeAudioService.transcriptStream.listen((text) {
          _handleIncomingTranscript(text, AudioSource.system, lang: _settings.speechLang);
        });
      }
    }
    notifyListeners();
  }

  // ── Mode Controls ──

  void setMode(OverlayMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  // ── Minimize / Expand ──

  Future<void> toggleMinimize() async {
    _settings.isMinimized = !_settings.isMinimized;
    await StorageService.saveSettings(_settings);
    await _updateWindowSizeForState();
    notifyListeners();
  }

  // ── Language Toggle ──

  Future<void> toggleLanguage() async {
    _settings.speechLang = _settings.speechLang == 'id-ID' ? 'en-US' : 'id-ID';
    await StorageService.saveSettings(_settings);

    // Restart native mic capture with newly selected language if mic is active
    if (_isMicActive) {
      await NativeAudioService.stopMicCapture();
      final success = await NativeAudioService.startMicCapture(
        apiKey: _settings.apiKey,
        apiProvider: _settings.apiProvider,
        lang: _settings.speechLang,
      );
      _isMicActive = success;
    }

    // Restart native system audio capture with newly selected language if system audio is active
    if (_isSystemAudioActive) {
      await NativeAudioService.stopSystemCapture();
      final success = await NativeAudioService.startSystemCapture(
        apiKey: _settings.apiKey,
        apiProvider: _settings.apiProvider,
        lang: _settings.speechLang,
      );
      _isSystemAudioActive = success;
    }

    notifyListeners();
  }

  // ── Settings Panel ──

  void toggleSettingsPanel() {
    _showSettingsPanel = !_showSettingsPanel;
    notifyListeners();
  }

  void updateSystemPrompt(String prompt) {
    _settings.systemPrompt = prompt;
    StorageService.saveSettings(_settings);
    notifyListeners();
  }

  /// Copy AI answer to clipboard.
  Future<void> copyAIAnswer() async {
    if (_transcript.aiAnswer.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _transcript.aiAnswer));
    }
  }

  // ── Existing methods (unchanged) ──

  Future<void> setOverlayVisibility(bool visible) async {
    _isPanicHidden = !visible;
    if (_isPanicHidden) {
      await WindowService.hideWindow();
    } else {
      await WindowService.showWindow();
    }
    notifyListeners();
  }

  Future<void> _applyNativeSettings() async {
    if (_settings.stealthEnabled) {
      await StealthService.enableStealthMode();
    } else {
      await StealthService.disableStealthMode();
    }
    await WindowService.setAlwaysOnTop(_settings.alwaysOnTop);
    await WindowService.setOpacity(_settings.opacity);
    await WindowService.setIgnoreMouseEvents(_settings.clickThrough);
  }

  Future<void> toggleStealthMode() async {
    _settings.stealthEnabled = !_settings.stealthEnabled;
    if (_settings.stealthEnabled) {
      await StealthService.enableStealthMode();
    } else {
      await StealthService.disableStealthMode();
    }
    await StorageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleClickThrough() async {
    _settings.clickThrough = !_settings.clickThrough;
    await WindowService.setIgnoreMouseEvents(_settings.clickThrough);
    await StorageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleShowGrid() async {
    _settings.showGrid = !_settings.showGrid;
    await StorageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setOpacity(double value) async {
    _settings.opacity = value.clamp(0.1, 1.0);
    await WindowService.setOpacity(_settings.opacity);
    await StorageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> togglePanicHide() async {
    _isPanicHidden = !_isPanicHidden;
    if (_isPanicHidden) {
      await WindowService.hideWindow();
    } else {
      await WindowService.showWindow();
    }
    notifyListeners();
  }

  void addNote({String title = 'New Note', String content = ''}) {
    final newNote = StickyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      x: 100 + (_notes.length * 20).toDouble(),
      y: 100 + (_notes.length * 20).toDouble(),
    );
    _notes.add(newNote);
    StorageService.saveNote(newNote);
    notifyListeners();
  }

  void updateNote(StickyNote updatedNote) {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      StorageService.saveNote(updatedNote);
      notifyListeners();
    }
  }

  void updateNotePosition(String id, double x, double y) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index].x = x;
      _notes[index].y = y;
      StorageService.saveNote(_notes[index]);
      notifyListeners();
    }
  }

  void updateNoteSize(String id, double width, double height) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index].width = width.clamp(180, 800);
      _notes[index].height = height.clamp(120, 600);
      StorageService.saveNote(_notes[index]);
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    StorageService.deleteNote(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _transcript.removeListener(_onTranscriptChanged);
    _transcript.dispose();
    _wsBridge.stop();
    _browserBridge.stop();
    super.dispose();
  }
}
