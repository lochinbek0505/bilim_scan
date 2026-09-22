import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TacticalBackground extends StatelessWidget {
  final Widget child;

  const TacticalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Solid Background Gradient (no alpha, no blur)
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),

          // Static Radar Grid
          CustomPaint(
            painter: _TacticalGridPainter(),
            size: Size.infinite,
          ),

          // Top Left & Bottom Right Tactical Viewfinder Corners
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TacticalFramePainter(),
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      // Toza qattiq rang (solid color), alpha aralashuvisiz
      ..color = const Color(0xFF141E30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 45.0;

    // Grid Lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalGridPainter oldDelegate) => false;
}

class _TacticalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // Toza qattiq rang (solid color), alpha aralashuvisiz
      ..color = AppColors.goldDark
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double cornerLen = 24.0;
    const double padding = 16.0;

    // Top-Left Corner
    canvas.drawLine(const Offset(padding, padding), const Offset(padding + cornerLen, padding), paint);
    canvas.drawLine(const Offset(padding, padding), const Offset(padding, padding + cornerLen), paint);

    // Top-Right Corner
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding - cornerLen, padding), paint);
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding, padding + cornerLen), paint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding + cornerLen, size.height - padding), paint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding, size.height - padding - cornerLen), paint);
    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding - cornerLen, size.height - padding), paint);
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding, size.height - padding - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
