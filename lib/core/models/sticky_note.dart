import 'package:flutter/material.dart';

class StickyNote {
  final String id;
  String title;
  String content;
  double x;
  double y;
  double width;
  double height;
  int colorValue;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;

  StickyNote({
    required this.id,
    required this.title,
    required this.content,
    this.x = 50,
    this.y = 50,
    this.width = 240,
    this.height = 180,
    this.colorValue = 0xFF2D2F36, // Dark slate default
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'colorValue': colorValue,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StickyNote.fromJson(Map<String, dynamic> json) {
    return StickyNote(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Note',
      content: json['content'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 50.0,
      y: (json['y'] as num?)?.toDouble() ?? 50.0,
      width: (json['width'] as num?)?.toDouble() ?? 240.0,
      height: (json['height'] as num?)?.toDouble() ?? 180.0,
      colorValue: json['colorValue'] as int? ?? 0xFF2D2F36,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  StickyNote copyWith({
    String? title,
    String? content,
    double? x,
    double? y,
    double? width,
    double? height,
    int? colorValue,
    bool? isPinned,
  }) {
    return StickyNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
