import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/heritage_site_details.dart';
import 'package:sageroute/components/heritage_site_filters.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/models/heritage_grade.dart';

void main() {
  testWidgets(
    'detail shows original history and missing photos on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final site = LocationRecord.fromMap({
        'id': 4,
        'name_modern': '安乐坊',
        'name_ancient': '安乐坊（后改名安济坊）',
        'address': '众安桥北一带',
        'period': '元祐五年',
        'historical_event': '捐金设病坊',
        'related_literature': '无',
        'literature_source': '《清波别志》',
        'research_notes': '今地位置据文献推定',
        'heritage_grade': '疑似',
        'themes': ['民生善政'],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: HeritageSiteDetails(site: site),
              ),
            ),
          ),
        ),
      );
      for (final text in [
        '安乐坊',
        '疑似',
        '今地',
        '时期',
        '历史事件',
        '相关诗文',
        '文献出处',
        '考订说明',
        '景点影像',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('尚未提供对应现场照片。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grade and theme controls report independent selections', (
    tester,
  ) async {
    HeritageGrade? grade;
    String? theme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeritageSiteFilters(
            grade: null,
            theme: null,
            onGradeChanged: (value) => grade = value,
            onThemeChanged: (value) => theme = value,
            onQueryChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '已佚'));
    expect(grade, HeritageGrade.lost);
    await tester.ensureVisible(find.text('民生善政'));
    await tester.tap(find.widgetWithText(ChoiceChip, '民生善政'));
    expect(theme, '民生善政');
  });
}
