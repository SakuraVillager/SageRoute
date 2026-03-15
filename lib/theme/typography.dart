import 'package:flutter/material.dart';
import 'color_schemes.dart';

/// Text styles used across the app.
TextTheme buildTextTheme() {
  return TextTheme(
    titleLarge: TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    bodyLarge: TextStyle(color: AppColors.onSurface, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 14),
  );
}
