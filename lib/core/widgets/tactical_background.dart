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
          // PNG rasm orqa fon
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main Screen Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

