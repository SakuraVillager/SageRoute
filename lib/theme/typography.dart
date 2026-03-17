import 'package:flutter/material.dart';

/// Text styles used across the app.
TextTheme buildTextTheme(ColorScheme scheme) {
  return TextTheme(
    titleLarge: TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16),
    bodyMedium: TextStyle(color: scheme.onSurface, fontSize: 14),
  );
}
