import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sticky_note.dart';
import '../models/settings.dart';

class StorageService {
  static const String _notesBoxName = 'stealth_notes';
  static const String _settingsBoxName = 'stealth_settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_notesBoxName);
    await Hive.openBox<String>(_settingsBoxName);
  }

  static List<StickyNote> loadNotes() {
    final box = Hive.box<String>(_notesBoxName);
    final List<StickyNote> notes = [];
    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          notes.add(StickyNote.fromJson(data));
        } catch (_) {}
      }
    }
    return notes;
  }

  static Future<void> saveNote(StickyNote note) async {
    final box = Hive.box<String>(_notesBoxName);
    await box.put(note.id, jsonEncode(note.toJson()));
  }

  static Future<void> deleteNote(String id) async {
    final box = Hive.box<String>(_notesBoxName);
    await box.delete(id);
  }

  static AppSettings loadSettings() {
    final box = Hive.box<String>(_settingsBoxName);
    final jsonStr = box.get('config');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return AppSettings.fromJson(data);
      } catch (_) {}
    }
    return AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box<String>(_settingsBoxName);
    await box.put('config', jsonEncode(settings.toJson()));
  }
}
