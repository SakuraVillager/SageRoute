import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'components.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get flatTheme {
    final colorScheme = AppColors.buildColorScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: buildAppBarTheme(),
      cardTheme: buildCardTheme(),
      elevatedButtonTheme: buildElevatedButtonTheme(),
      textButtonTheme: buildTextButtonTheme(),
      inputDecorationTheme: buildInputDecorationTheme(),
      dividerTheme: buildDividerTheme(),
      textTheme: buildTextTheme(),
    );
  }
}
