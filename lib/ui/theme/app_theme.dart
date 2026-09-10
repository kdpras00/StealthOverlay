import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors (Dark slate mode for high legibility over desktop backgrounds)
  static const Color darkBackground = Color(0xCC18191E);
  static const Color surfaceColor = Color(0xEE22242B);
  static const Color cardColor = Color(0xF72D3039);
  static const Color accentColor = Color(0xFF6366F1); // Indigo
  static const Color stealthGreen = Color(0xFF10B981); // Emerald Green
  static const Color warningOrange = Color(0xFFF59E0B); // Amber
  static const Color panicRed = Color(0xFFEF4444); // Crimson

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color borderSubtle = Color(0x33FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: stealthGreen,
        surface: surfaceColor,
        error: panicRed,
      ),
      fontFamily: 'SF Pro Text',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }

  static BoxDecoration glassContainer({
    Color? color,
    double borderRadius = 12.0,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: showBorder
          ? Border.all(color: borderSubtle, width: 1.0)
          : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
