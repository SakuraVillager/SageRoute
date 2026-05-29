import 'package:flutter/material.dart';

/// Text styles used across the app.
TextTheme buildTextTheme(ColorScheme scheme) {
  return TextTheme(
    headlineMedium: TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 28,
    ),
    headlineSmall: TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16),
    bodyMedium: TextStyle(color: scheme.onSurface, fontSize: 14),
    bodySmall: TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    labelSmall: TextStyle(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    ),
  );
}
