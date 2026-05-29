import 'package:flutter/material.dart';

AppBarTheme buildAppBarTheme(ColorScheme scheme) => AppBarTheme(
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: scheme.primary,
  foregroundColor: scheme.onPrimary,
  centerTitle: true,
);

CardThemeData buildCardTheme(ColorScheme scheme) => CardThemeData(
  elevation: 0,
  color: scheme.surfaceContainerLow,
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(
      color: scheme.outline,
    ),
  ),
);

ElevatedButtonThemeData buildElevatedButtonTheme(ColorScheme scheme) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

TextButtonThemeData buildTextButtonTheme(ColorScheme scheme) =>
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

InputDecorationTheme buildInputDecorationTheme(ColorScheme scheme) =>
    InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
    );

DividerThemeData buildDividerTheme(ColorScheme scheme) => DividerThemeData(
  space: 1,
  thickness: 0.5,
  color: scheme.primary.withAlpha((0.1 * 255).round()),
);
