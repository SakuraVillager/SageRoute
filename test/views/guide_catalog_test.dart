import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/dongpo_site_repository.dart';
import 'package:sageroute/data/supabase_table_repository.dart';
import 'package:sageroute/pages/guide/guide_page.dart';
import 'package:sageroute/components/map/map_types.dart';

void main() {
  testWidgets(
    'map and directory combine filters and keep unlocated site details accessible',
    (tester) async {
      final rows = jsonDecode(
        File('assets/data/dongpo_sites.json').readAsStringSync(),
      );
      var markers = <MapMarkerData>{};
      final repository = DongpoSiteRepository(
        table: SupabaseTableRepository(
          tableName: 'dongpo_sites',
          rawFetcher:
              ({required tableName, required columns, limit, equals}) async =>
                  rows,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuidePage(
              repository: repository,
              mapBuilder: (context, visibleMarkers) {
                markers = visibleMarkers;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 10 && markers.length != 30; attempt++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pumpAndSettle();
      expect(markers.length, 30);
      expect(find.text('37 个景点 · 30 个有地图位置'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '疑似'));
      await tester.pumpAndSettle();
      expect(markers.length, 1);
      expect(find.text('2 个景点 · 1 个有地图位置'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('龙华寺题名'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('龙华寺题名'));
      await tester.pumpAndSettle();
      expect(find.text('文献出处'), findsOneWidget);
      expect(find.text('景点影像'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭详情'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '水利治绩'));
      await tester.tap(find.widgetWithText(ChoiceChip, '水利治绩'));
      await tester.pumpAndSettle();
      expect(markers, isEmpty);
      expect(find.text('没有符合条件的景点，请调整等级、专题或搜索词。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
