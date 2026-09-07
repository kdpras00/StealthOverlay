import 'package:flutter_test/flutter_test.dart';
import 'package:stealth_overlay/core/models/sticky_note.dart';
import 'package:stealth_overlay/core/models/settings.dart';

void main() {
  group('StickyNote Model Tests', () {
    test('Should correctly create and serialize StickyNote to JSON', () {
      final note = StickyNote(
        id: 'test_1',
        title: 'Test Note',
        content: 'Sample Content',
        x: 120,
        y: 150,
        width: 300,
        height: 200,
      );

      expect(note.id, 'test_1');
      expect(note.title, 'Test Note');
      expect(note.content, 'Sample Content');

      final json = note.toJson();
      expect(json['id'], 'test_1');
      expect(json['x'], 120.0);
      expect(json['colorValue'], 0xFF2D2F36);

      final deserialized = StickyNote.fromJson(json);
      expect(deserialized.id, 'test_1');
      expect(deserialized.title, 'Test Note');
      expect(deserialized.width, 300.0);
    });

    test('StickyNote copyWith should create updated copy', () {
      final note = StickyNote(
        id: 'note_2',
        title: 'Original Title',
        content: 'Original Content',
      );

      final updated = note.copyWith(title: 'Updated Title', x: 250);
      expect(updated.id, 'note_2');
      expect(updated.title, 'Updated Title');
      expect(updated.content, 'Original Content');
      expect(updated.x, 250.0);
    });
  });

  group('AppSettings Model Tests', () {
    test('AppSettings default values should match specification', () {
      final settings = AppSettings();
      expect(settings.stealthEnabled, true);
      expect(settings.alwaysOnTop, true);
      expect(settings.clickThrough, false);
      expect(settings.opacity, 0.85);
      expect(settings.serverPort, 8765);
    });
  });
}
