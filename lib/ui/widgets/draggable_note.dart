import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/sticky_note.dart';
import '../providers/overlay_provider.dart';
import '../theme/app_theme.dart';

class DraggableNoteWidget extends StatefulWidget {
  final StickyNote note;

  const DraggableNoteWidget({super.key, required this.note});

  @override
  State<DraggableNoteWidget> createState() => _DraggableNoteWidgetState();
}

class _DraggableNoteWidgetState extends State<DraggableNoteWidget> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isHovered = false;

  final List<int> _colorOptions = const [
    0xFF2D2F36, // Dark Slate
    0xFF1F2937, // Charcoal
    0xFF1E3A8A, // Ocean Navy
    0xFF064E3B, // Forest Emerald
    0xFF4C1D95, // Deep Violet
    0xFF881337, // Dark Burgundy
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void didUpdateWidget(covariant DraggableNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.title != widget.note.title) {
      _titleController.text = widget.note.title;
    }
    if (oldWidget.note.content != widget.note.content) {
      _contentController.text = widget.note.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OverlayProvider>();

    return Positioned(
      left: widget.note.x,
      top: widget.note.y,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: widget.note.width,
          height: widget.note.height,
          decoration: BoxDecoration(
            color: Color(widget.note.colorValue).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppTheme.accentColor : AppTheme.borderSubtle,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Drag Handle
              GestureDetector(
                onPanUpdate: (details) {
                  provider.updateNotePosition(
                    widget.note.id,
                    (widget.note.x + details.delta.dx).clamp(0, 2000),
                    (widget.note.y + details.delta.dy).clamp(0, 1500),
                  );
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (text) {
                            widget.note.title = text;
                            provider.updateNote(widget.note);
                          },
                        ),
                      ),
                      // Palette button
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.color_lens_outlined, size: 15, color: AppTheme.textSecondary),
                        tooltip: 'Change Note Color',
                        onSelected: (colorVal) {
                          widget.note.colorValue = colorVal;
                          provider.updateNote(widget.note);
                        },
                        itemBuilder: (context) => _colorOptions.map((c) {
                          return PopupMenuItem<int>(
                            value: c,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c == 0xFF2D2F36 ? 'Slate' : 'Color',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      // Delete button
                      InkWell(
                        onTap: () => provider.deleteNote(widget.note.id),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type note or snippet here...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (text) {
                      widget.note.content = text;
                      provider.updateNote(widget.note);
                    },
                  ),
                ),
              ),

              // Bottom Resize Handle
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    provider.updateNoteSize(
                      widget.note.id,
                      widget.note.width + details.delta.dx,
                      widget.note.height + details.delta.dy,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.aspect_ratio_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
