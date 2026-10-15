import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/dongpo_site_repository.dart';
import 'package:sageroute/data/location_repository.dart';
import 'package:sageroute/data/poi_celebrity_relation_repository.dart';
import 'package:sageroute/data/topic_repository.dart';
import 'package:sageroute/models/celebrity_profile.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/views/create_route_wizard/steps/add_place_page.dart';

class _LocalCatalog extends DongpoSiteRepository {
  const _LocalCatalog();
  @override
  Future<DongpoCatalog> fetchCatalog() => fetchLocalCatalog();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await rootBundle.loadString('assets/data/dongpo_sites.json');
    await rootBundle.loadString('assets/data/dongpo_planning_metadata.json');
  });
  Future<void> openPicker(
    WidgetTester tester, {
    String figureName = '苏轼',
    List<LocationRecord> existing = const [],
    ValueChanged<List<RoutePlace>?>? onResult,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('选点'),
              onPressed: () async => onResult?.call(
                await showModalBottomSheet<List<RoutePlace>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddPlacePage(
                    figure: CelebrityProfile(
                      id: 1,
                      name: figureName,
                      dynasty: '宋',
                      bioShort: '',
                      bioFull: '',
                      avatarUrl: '',
                      topic: const [],
                    ),
                    currentSelectedPlaces: const [],
                    locationRepository: LocationRepository(
                      fetcher: () async => existing,
                    ),
                    topicRepository: TopicRepository(fetcher: () async => []),
                    relationRepository: PoiCelebrityRelationRepository(
                      fetcher: () async => [],
                    ),
                    dongpoRepository: const _LocalCatalog(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('选点'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'theme and grade filters combine, details remain accessible for unlocated sites',
    (tester) async {
      await openPicker(tester, onResult: (_) {});
      expect(find.text('37 个地点 · 30 个可加入路线'), findsOneWidget);
      await tester.tap(find.text('东坡杭州行迹').first);
      await tester.pumpAndSettle();
      final water = find.widgetWithText(FilterChip, '水利治绩');
      await tester.ensureVisible(water);
      await tester.tap(water);
      await tester.pumpAndSettle();
      expect(find.text('4 个地点 · 3 个可加入路线'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, '已佚'));
      await tester.pumpAndSettle();
      expect(find.text('1 个地点 · 0 个可加入路线'), findsOneWidget);
      expect(find.text('钱塘江石门（开石门河状）'), findsOneWidget);
      await tester.tap(find.text('钱塘江石门（开石门河状）'));
      await tester.pumpAndSettle();
      expect(find.text('考订说明'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭地点详情'));
      await tester.pumpAndSettle();
      expect(find.text('未选择地点'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selecting a catalog place returns its grade, category and full details',
    (tester) async {
      List<RoutePlace>? selected;
      await openPicker(tester, onResult: (places) => selected = places);
      await tester.enterText(find.byType(TextField), '望湖楼');
      await tester.pumpAndSettle();
      expect(find.text('亭台楼阁'), findsOneWidget);
      await tester.tap(find.text('望湖楼').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(selected, hasLength(1));
      expect(selected!.single.heritageGrade!.label, '确证');
      expect(selected!.single.details!.literatureSource, isNotEmpty);
      expect(selected!.single.details!.photos, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reference toggle enables located places and disabling it clears their selection',
    (tester) async {
      final catalog = await tester.runAsync(
        () => const _LocalCatalog().fetchCatalog(),
      );
      final source = catalog!.sites.singleWhere((site) => site.id == 17);
      List<RoutePlace>? selected;
      await openPicker(
        tester,
        existing: [source.copyWith(id: 117, routeEligible: false)],
        onResult: (places) => selected = places,
      );
      await tester.enterText(find.byType(TextField), '望湖楼');
      await tester.pumpAndSettle();
      expect(find.text('1 个地点 · 0 个可加入路线'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('1 个地点 · 1 个可加入路线'), findsOneWidget);
      await tester.tap(find.text('望湖楼').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('未选择地点'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '钱塘江石门');
      await tester.pumpAndSettle();
      expect(find.text('1 个地点 · 0 个可加入路线'), findsOneWidget);
      expect(find.text('暂无坐标 · 暂不可加入路线'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '望湖楼');
      await tester.pumpAndSettle();
      await tester.tap(find.text('望湖楼').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(selected, hasLength(1));
      expect(selected!.single.id, 117);
      expect(selected!.single.details!.routeEligible, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'other historical figures do not inherit Dongpo places or theme',
    (tester) async {
      await openPicker(tester, figureName: '白居易', onResult: (_) {});
      expect(find.text('0 个地点 · 0 个可加入路线'), findsOneWidget);
      expect(find.text('东坡杭州行迹'), findsNothing);
    },
  );
}
