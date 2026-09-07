import 'package:flutter/material.dart';

class GridOverlayWidget extends StatelessWidget {
  final double gridSize;
  final Color gridColor;

  const GridOverlayWidget({
    super.key,
    this.gridSize = 30.0,
    this.gridColor = const Color(0x1AFFFFFF), // Subtle translucent white
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GridPainter(gridSize: gridSize, gridColor: gridColor),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  _GridPainter({required this.gridSize, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize || oldDelegate.gridColor != gridColor;
  }
}
