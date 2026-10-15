import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/location_repository.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/services/database_service.dart';
import 'package:sageroute/data/supabase_table_repository.dart';

void main() {
  test('theme lookup reads memberships and preserves grade and tags', () async {
    final repository = LocationRepository(
      topicLocationsRepository: SupabaseTableRepository(
        tableName: 'route_topic_locations',
        rawFetcher:
            ({required tableName, required columns, limit, equals}) async {
              expect(equals, {'theme_name': '苏轼·杭州行迹'});
              return [
                {
                  'id (PK)': 67,
                  'name_modern': '钱塘六井',
                  'Topic': '苏轼·西湖治水与六井',
                  'heritage_grade': '确证',
                  'themes': ['水利治绩', '民生善政'],
                },
              ];
            },
      ),
    );
    final rows = await repository.fetchLocationsByTopic('苏轼·杭州行迹');
    expect(rows.single.id, 67);
    expect(rows.single.heritageGrade?.label, '确证');
    expect(rows.single.themes, ['水利治绩', '民生善政']);
  });
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchLocations returns rows from mock fetcher', () async {
    var callCount = 0;
    final repository = LocationRepository(
      fetcher: () async {
        callCount += 1;
        return const <LocationRecord>[
          LocationRecord(
            id: 1,
            nameModern: '西湖',
            nameAncient: null,
            description: '上有天堂下有苏杭',
            averageVisitDurationMin: 120,
            address: '杭州市西湖区',
            openTime: null,
            closeTime: null,
            isArEnabled: false,
            topic: null,
            categories: <String>[],
            coordinates: <double>[120.14, 30.24],
          ),
          LocationRecord(
            id: 2,
            nameModern: '岳王庙',
            nameAncient: null,
            description: '岳飞庙',
            averageVisitDurationMin: 60,
            address: null,
            openTime: null,
            closeTime: null,
            isArEnabled: true,
            topic: null,
            categories: <String>[],
            coordinates: <double>[120.15, 30.25],
          ),
        ];
      },
    );

    final rows = await repository.fetchLocations();

    expect(callCount, 1);
    expect(rows, hasLength(2));
    expect(rows.first.nameModern, '西湖');
    expect(rows.last.isArEnabled, isTrue);
    expect(rows.first.longitude, 120.14);
    expect(rows.first.latitude, 30.24);
  });

  test(
    'fetchLocations returns empty list when fetcher yields no data',
    () async {
      final repository = LocationRepository(
        fetcher: () async => const <LocationRecord>[],
      );

      final rows = await repository.fetchLocations();

      expect(rows, isEmpty);
    },
  );

  test('fetchLocations propagates error from fetcher', () async {
    final repository = LocationRepository(
      fetcher: () async => throw Exception('网络超时'),
    );

    expect(() => repository.fetchLocations(), throwsException);
  });
}
