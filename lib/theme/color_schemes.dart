import 'package:flutter/material.dart';

/// Cool neutral surfaces paired with the warm #96615A brand color.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color brand = Color(0xFF96615A);

  // Brand mixed with black (increasing depth).
  static const Color brandDark = Color(0xFF784E48);
  static const Color brandDeeper = Color(0xFF5A3A36);
  static const Color brandInk = Color(0xFF3C2724);
  static const Color brandNearBlack = Color(0xFF2D1D1B);

  // Brand mixed with white (increasing lightness).
  static const Color brandMedium = Color(0xFFAB817B);
  static const Color brandPale = Color(0xFFC0A09C);
  static const Color brandSoft = Color(0xFFD5C0BD);
  static const Color brandLight = Color(0xFFEADFDE);
  static const Color brandWash = Color(0xFFF5EFEF);

  // Neutral surfaces and content colors.
  static const Color neutralBg = Color(0xFFF0F0F2);
  static const Color neutralSoft = Color(0xFFF8F8F9);
  static const Color neutralCard = white;
  static const Color neutralBorder = Color(0xFFD8D8DC);
  static const Color neutralMuted = Color(0xFF6F6D72);
  static const Color neutralText = Color(0xFF202124);
  static const Color brandSurface = neutralBg;

  // Semantic aliases used throughout the existing UI.
  static const Color sageBg = brandSurface;
  static const Color sageCard = neutralCard;
  static const Color sageText = neutralText;
  static const Color sageMuted = neutralMuted;
  static const Color sageAccent = brand;
  static const Color sageBorder = neutralBorder;
  static const Color sageDeep = brand;

  // Compatibility aliases: formerly green/gold, now brand-derived by design.
  static const Color sageGreen = brandDark;
  static const Color sageGold = brandMedium;

  // Light mode colors.
  static const Color primaryLight = brand;
  static const Color secondaryLight = brandDark;
  static const Color tertiaryLight = brandMedium;
  static const Color errorLight = brandDark;
  static const Color neutralLight = neutralBg;
  static const Color neutralVariantLight = neutralBorder;

  // Dark mode colors.
  static const Color primaryDark = brandSoft;
  static const Color secondaryDark = brandPale;
  static const Color tertiaryDark = brandSoft;
  static const Color errorDark = brandSoft;
  static const Color neutralDark = neutralText;
  static const Color neutralVariantDark = neutralMuted;

  static const Color surfaceLight = brandSurface;
  static const Color onPrimaryLight = white;
  static const Color onSurfaceLight = neutralText;

  static const Color surfaceDark = neutralText;
  static const Color onPrimaryDark = brandNearBlack;
  static const Color onSurfaceDark = neutralSoft;

  static ColorScheme buildLightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: white,
      tertiary: tertiaryLight,
      onTertiary: neutralText,
      error: errorLight,
      onError: white,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      inversePrimary: brand,
      shadow: neutralText,
      outline: neutralVariantLight,
      surfaceTint: primaryLight,
      surfaceContainerHighest: neutralBorder,
      surfaceContainerHigh: neutralSoft,
      surfaceContainer: neutralBg,
      surfaceContainerLow: neutralSoft,
      surfaceContainerLowest: neutralCard,
      outlineVariant: neutralBorder,
    );
  }

  static ColorScheme buildDarkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: brandNearBlack,
      tertiary: tertiaryDark,
      onTertiary: brandNearBlack,
      error: errorDark,
      onError: brandNearBlack,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      inversePrimary: primaryLight,
      shadow: black,
      outline: neutralVariantDark,
      surfaceTint: primaryDark,
      surfaceContainerHighest: neutralMuted,
      surfaceContainerHigh: brandNearBlack,
      surfaceContainer: neutralText,
      surfaceContainerLow: neutralText,
      surfaceContainerLowest: black,
      outlineVariant: neutralMuted,
    );
  }
}
