import 'package:flutter/material.dart';

/// Centralizes brand colors and derived tones.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF926B62);
  static const Color scaffoldBackground = Color(0xFFFDFBFB);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF2C2624);

  static final Color secondary = primary.withValues(alpha: 0.8);
  static final Color borderSubtle = primary.withValues(alpha: 0.2);
  static final Color dividerSubtle = primary.withValues(alpha: 0.1);

  static ColorScheme buildColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: onPrimary,
      onSurface: onSurface,
      brightness: Brightness.light,
    );
  }
}
