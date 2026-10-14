import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/color_schemes.dart';

/// Samples a small thumbnail, keeping decoding and temporary image ownership
/// independent of the image displayed by the carousel.
class FeaturedImagePalette {
  FeaturedImagePalette._();

  static Future<Color> backgroundFor(ui.Image source) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      const Rect.fromLTWH(0, 0, 24, 24),
      Paint()..filterQuality = FilterQuality.low,
    );
    final picture = recorder.endRecording();
    final thumbnail = await picture.toImage(24, 24);
    picture.dispose();
    try {
      final pixels = await thumbnail.toByteData();
      if (pixels == null) return AppColors.brandWash;
      var red = 0.0;
      var green = 0.0;
      var blue = 0.0;
      var weights = 0.0;
      for (var i = 0; i < pixels.lengthInBytes; i += 4) {
        final r = pixels.getUint8(i);
        final g = pixels.getUint8(i + 1);
        final b = pixels.getUint8(i + 2);
        final max = [r, g, b].reduce((a, b) => a > b ? a : b);
        final min = [r, g, b].reduce((a, b) => a < b ? a : b);
        // Saturated pixels carry more of the photograph's color identity.
        final weight = (pixels.getUint8(i + 3) / 255) * (1 + (max - min) / 64);
        red += r * weight;
        green += g * weight;
        blue += b * weight;
        weights += weight;
      }
      if (weights == 0) return AppColors.brandWash;
      final color = HSLColor.fromColor(
        Color.fromARGB(
          255,
          (red / weights).round(),
          (green / weights).round(),
          (blue / weights).round(),
        ),
      );
      return color
          .withSaturation(color.saturation.clamp(0, .45))
          .withLightness(.82)
          .toColor();
    } finally {
      thumbnail.dispose();
    }
  }
}
