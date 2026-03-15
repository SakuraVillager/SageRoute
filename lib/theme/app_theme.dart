import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'components.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme {
    final colorScheme = AppColors.buildLightScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: buildAppBarTheme(colorScheme),
      cardTheme: buildCardTheme(colorScheme),
      elevatedButtonTheme: buildElevatedButtonTheme(colorScheme),
      textButtonTheme: buildTextButtonTheme(colorScheme),
      inputDecorationTheme: buildInputDecorationTheme(colorScheme),
      dividerTheme: buildDividerTheme(colorScheme),
      textTheme: buildTextTheme(colorScheme),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = AppColors.buildDarkScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: buildAppBarTheme(colorScheme),
      cardTheme: buildCardTheme(colorScheme),
      elevatedButtonTheme: buildElevatedButtonTheme(colorScheme),
      textButtonTheme: buildTextButtonTheme(colorScheme),
      inputDecorationTheme: buildInputDecorationTheme(colorScheme),
      dividerTheme: buildDividerTheme(colorScheme),
      textTheme: buildTextTheme(colorScheme),
    );
  }
}
