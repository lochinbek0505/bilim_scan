import 'package:flutter/material.dart';

class AppColors {
  // Asosiy to'q ranglar (IIV & Kuch ishlatar tizimlar tactical blue)
  static const Color backgroundDark = Color(0xFF070C18);
  static const Color backgroundSecondary = Color(0xFF0F182A);
  static const Color cardDark = Color(0xFF142036);
  static const Color cardBorder = Color(0xFF223454);
  static const Color inputBackground = Color(0xFF0D1526);

  // IIV Oltin ranglari (Gerbdagi oltin va bronza tuslari)
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFA38020);
  static const Color goldGlow = Color(0x66D4AF37);

  // Litsey Yashil ranglari (Litsey gerbidagi to'q yashil)
  static const Color emeraldPrimary = Color(0xFF0D5C3A);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x6610B981);

  // Status va Matn ranglari
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status ranglari
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Overlay va Gradiyentlar
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B132B),
      Color(0xFF070C18),
      Color(0xFF040810),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5D77F),
      Color(0xFFD4AF37),
      Color(0xFFA38020),
    ],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF0D5C3A),
      Color(0xFF063823),
    ],
  );
}
