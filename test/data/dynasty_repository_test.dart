import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/dynasty_repository.dart';
import 'package:sageroute/models/dynasty_record.dart';
import 'package:sageroute/services/database_service.dart';

void main() {
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchDynasties returns rows from mock fetcher', () async {
    var callCount = 0;
    final repository = DynastyRepository(
      fetcher: () async {
        callCount += 1;
        return const <DynastyRecord>[
          DynastyRecord(id: 1, dynasty: '唐'),
          DynastyRecord(id: 2, dynasty: '宋'),
          DynastyRecord(id: 3, dynasty: '元'),
        ];
      },
    );

    final rows = await repository.fetchDynasties();

    expect(callCount, 1);
    expect(rows, hasLength(3));
    expect(rows.first.dynasty, '唐');
    expect(rows.last.dynasty, '元');
  });

  test('fetchDynasties returns empty list when fetcher yields no data', () async {
    final repository = DynastyRepository(
      fetcher: () async => const <DynastyRecord>[],
    );

    final rows = await repository.fetchDynasties();

    expect(rows, isEmpty);
  });

  test('fetchDynasties propagates error from fetcher', () async {
    final repository = DynastyRepository(
      fetcher: () async => throw Exception('模拟网络错误'),
    );

    expect(
      () => repository.fetchDynasties(),
      throwsException,
    );
  });
}
