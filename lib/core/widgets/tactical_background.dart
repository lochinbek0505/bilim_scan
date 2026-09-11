import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TacticalBackground extends StatefulWidget {
  final Widget child;

  const TacticalBackground({super.key, required this.child});

  @override
  State<TacticalBackground> createState() => _TacticalBackgroundState();
}

class _TacticalBackgroundState extends State<TacticalBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),

          // Animated Radar Grid & Ambient Glows
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _TacticalGridPainter(_controller.value),
                size: Size.infinite,
              );
            },
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
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  final double animationValue;

  _TacticalGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.25)
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

    // Ambient Glowing Radar Radial
    final center = Offset(size.width * 0.3, size.height * 0.4);
    final pulseRadius = (size.width * 0.35) + (math.sin(animationValue * 2 * math.pi) * 30);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldPrimary.withValues(alpha: 0.08),
          AppColors.emeraldAccent.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: pulseRadius));

    canvas.drawCircle(center, pulseRadius, glowPaint);

    // Right Side Secondary Glow
    final rightCenter = Offset(size.width * 0.8, size.height * 0.7);
    final rightGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.emeraldAccent.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: rightCenter, radius: 250));

    canvas.drawCircle(rightCenter, 250, rightGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _TacticalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.goldPrimary.withValues(alpha: 0.4)
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
