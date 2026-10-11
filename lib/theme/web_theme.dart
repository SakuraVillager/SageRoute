import 'package:flutter/material.dart';
import 'color_schemes.dart';

/// Web controls share the brand but use compact, flat browser conventions.
ThemeData browserTheme(ThemeData base) => base.copyWith(
  visualDensity: VisualDensity.compact,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.brandDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.sageBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.brand),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
);
