import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/map/category_marker_icons.dart';

void main() {
  test('maps Chinese place categories to semantic marker icons', () {
    expect(categoryMarkerKindFor('寺庙, 古迹'), CategoryMarkerKind.temple);
    expect(categoryMarkerKindFor('古迹、宫殿'), CategoryMarkerKind.palace);
    expect(categoryMarkerKindFor('园林'), CategoryMarkerKind.garden);
    expect(categoryMarkerKindFor('自然景观'), CategoryMarkerKind.nature);
    expect(categoryMarkerKindFor('历史桥梁'), CategoryMarkerKind.bridge);
    expect(categoryMarkerKindFor('名人故居'), CategoryMarkerKind.residence);
    expect(categoryMarkerKindFor('博物馆'), CategoryMarkerKind.heritage);
  });

  test('uses a custom generic icon for missing or unknown categories', () {
    expect(categoryMarkerKindFor(null), CategoryMarkerKind.generic);
    expect(categoryMarkerKindFor(''), CategoryMarkerKind.generic);
    expect(categoryMarkerKindFor('其他'), CategoryMarkerKind.generic);
  });

  testWidgets('rasterizes every SVG marker kind', (tester) async {
    final icons = await tester.runAsync(
      () => buildCategoryMarkerIcons(fillColor: const Color(0xFF96615A)),
    );

    expect(icons, isNotNull);
    expect(icons, hasLength(CategoryMarkerKind.values.length));
  });
}
