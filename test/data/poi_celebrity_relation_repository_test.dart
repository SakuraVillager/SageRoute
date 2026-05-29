import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/poi_celebrity_relation_repository.dart';
import 'package:sageroute/models/poi_celebrity_relation_record.dart';
import 'package:sageroute/services/database_service.dart';

void main() {
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchRelations returns rows from mock fetcher', () async {
    var callCount = 0;
    final repository = PoiCelebrityRelationRepository(
      fetcher: () async {
        callCount += 1;
        return const <PoiCelebrityRelationRecord>[
          PoiCelebrityRelationRecord(
            id: 1,
            createdAt: null,
            locationName: '西湖',
            celebrityName: '苏东坡',
            relationType: '曾任官职',
            weight: 10,
          ),
          PoiCelebrityRelationRecord(
            id: 2,
            createdAt: null,
            locationName: '西湖',
            celebrityName: '白居易',
            relationType: '曾任官职',
            weight: 8,
          ),
          PoiCelebrityRelationRecord(
            id: 3,
            createdAt: null,
            locationName: '岳王庙',
            celebrityName: '岳飞',
            relationType: '故居',
            weight: 12,
          ),
        ];
      },
    );

    final rows = await repository.fetchRelations();

    expect(callCount, 1);
    expect(rows, hasLength(3));
    expect(rows.first.celebrityName, '苏东坡');
    expect(rows.first.locationName, '西湖');
    expect(rows.last.weight, 12);
  });

  test('fetchRelations returns empty list when fetcher yields no data', () async {
    final repository = PoiCelebrityRelationRepository(
      fetcher: () async => const <PoiCelebrityRelationRecord>[],
    );

    final rows = await repository.fetchRelations();

    expect(rows, isEmpty);
  });

  test('fetchRelations propagates error from fetcher', () async {
    final repository = PoiCelebrityRelationRepository(
      fetcher: () async => throw Exception('数据库异常'),
    );

    expect(
      () => repository.fetchRelations(),
      throwsException,
    );
  });
}
