import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle titleHeader = GoogleFonts.cinzel(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.goldPrimary,
    letterSpacing: 1.5,
  );

  static TextStyle titleSubHeader = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle badgeText = GoogleFonts.rajdhani(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.emeraldAccent,
    letterSpacing: 1.8,
  );

  static TextStyle buttonText = GoogleFonts.montserrat(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.backgroundDark,
    letterSpacing: 1.2,
  );
}
