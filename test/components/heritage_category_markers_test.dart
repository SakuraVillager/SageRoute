import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/map/category_marker_icons.dart';
import 'package:sageroute/models/heritage_grade.dart';
import 'package:sageroute/theme/color_schemes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all category icons preserve their glyph and rasterize each grade background',
    () async {
      final icons = await buildHeritageCategoryMarkerIcons();
      for (final grade in <HeritageGrade?>[null, ...HeritageGrade.values]) {
        expect(icons[grade]!.length, CategoryMarkerKind.values.length);
        final color = grade?.color ?? AppColors.sageAccent;
        final codec = await ui.instantiateImageCodec(
          icons[grade]![CategoryMarkerKind.palace]!.bytes!,
        );
        final frame = await codec.getNextFrame();
        final rgba = await frame.image.toByteData();
        // Inside the colored disk and outside the centered white category glyph.
        final offset = (20 * frame.image.width + 42) * 4;
        expect(rgba!.getUint8(offset), (color.toARGB32() >> 16) & 255);
        expect(rgba.getUint8(offset + 1), (color.toARGB32() >> 8) & 255);
        expect(rgba.getUint8(offset + 2), color.toARGB32() & 255);
        frame.image.dispose();
        codec.dispose();
      }
      expect(categoryMarkerKindFor('亭台楼阁'), CategoryMarkerKind.palace);
      expect(categoryMarkerKindFor('泉池溪涧'), CategoryMarkerKind.nature);
    },
  );
}
