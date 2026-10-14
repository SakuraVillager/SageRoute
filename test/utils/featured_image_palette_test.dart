import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/theme/color_schemes.dart';
import 'package:sageroute/utils/featured_image_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final color in [Colors.red, Colors.blue, Colors.green]) {
    test(
      'background retains the hue of $color as a light solid color',
      () async {
        final recorder = ui.PictureRecorder();
        Canvas(
          recorder,
        ).drawRect(const Rect.fromLTWH(0, 0, 12, 12), Paint()..color = color);
        final picture = recorder.endRecording();
        final source = await picture.toImage(12, 12);
        picture.dispose();
        addTearDown(source.dispose);
        final background = await FeaturedImagePalette.backgroundFor(source);
        final palette = HSLColor.fromColor(background);
        expect(palette.hue, closeTo(HSLColor.fromColor(color).hue, 2));
        expect(palette.lightness, closeTo(.82, .01));
        expect(background.a, 1);
      },
    );
  }

  test('transparent image keeps the brand fallback', () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder);
    final picture = recorder.endRecording();
    final source = await picture.toImage(12, 12);
    picture.dispose();
    addTearDown(source.dispose);
    expect(
      await FeaturedImagePalette.backgroundFor(source),
      AppColors.brandWash,
    );
  });
}
