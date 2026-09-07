import 'package:flutter/material.dart';
import '../../core/models/sticky_note.dart';
import '../../core/models/settings.dart';
import '../../core/services/stealth_service.dart';
import '../../core/services/window_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/browser_bridge_service.dart';

class OverlayProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  List<StickyNote> _notes = [];
  bool _isPanicHidden = false;
  bool _isMacOSSequoia = false;
  final BrowserBridgeService _browserBridge = BrowserBridgeService();

  AppSettings get settings => _settings;
  List<StickyNote> get notes => _notes;
  bool get isPanicHidden => _isPanicHidden;
  bool get isMacOSSequoia => _isMacOSSequoia;
  bool get isStealthEnabled => _settings.stealthEnabled;
  bool get isClickThrough => _settings.clickThrough;
  bool get showGrid => _settings.showGrid;
  double get opacity => _settings.opacity;

  OverlayProvider() {
    _init();
  }

  Future<void> _init() async {
    _settings = StorageService.loadSettings();
    _notes = StorageService.loadNotes();

    // Default note if empty
    if (_notes.isEmpty) {
      _notes.add(
        StickyNote(
          id: 'welcome_note',
          title: '📌 Stealth Overlay Quick Guide',
          content: '• Press ⌘+Shift+H (or Ctrl+Shift+H) to Panic Hide.\n'
              '• Toggle Stealth Mode with ⌘+Shift+S.\n'
              '• Click Lock icon to enable click-through mode.\n'
              '• Drag notes by title bar to position anywhere.',
          x: 40,
          y: 80,
          width: 320,
          height: 180,
        ),
      );
      await StorageService.saveNote(_notes.first);
    }

    _isMacOSSequoia = await StealthService.isMacOSSequoiaOrLater();

    // Sync native window state
    await _applyNativeSettings();

    // Start browser bridge
    await _browserBridge.start(
      port: _settings.serverPort,
      initialVisible: !_isPanicHidden,
      onNoteReceived: (title, content) {
        addNote(title: title, content: content);
      },
      onVisibilityToggled: (visible) {
        setOverlayVisibility(visible);
      },
    );

    notifyListeners();
  }

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
}
