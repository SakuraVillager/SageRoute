import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/icon_repository.dart';
import 'package:sageroute/models/icon_record.dart';
import 'package:sageroute/services/database_service.dart';

void main() {
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchIcons returns rows from mock fetcher', () async {
    var callCount = 0;
    final repository = IconRepository(
      fetcher: () async {
        callCount += 1;
        return const <IconRecord>[
          IconRecord(name: '寺庙', svg: 'M10 20...'),
          IconRecord(name: '塔', svg: 'M12 18...'),
        ];
      },
    );

    final rows = await repository.fetchIcons();

    expect(callCount, 1);
    expect(rows, hasLength(2));
    expect(rows.first.name, '寺庙');
    expect(rows.last.svg, 'M12 18...');
  });

  test('fetchIconMap returns name → svg map from mock fetcher', () async {
    final repository = IconRepository(
      fetcher: () async => const <IconRecord>[
        IconRecord(name: '寺庙', svg: 'M10 20...'),
        IconRecord(name: '塔', svg: 'M12 18...'),
        IconRecord(name: '园林', svg: 'M14 16...'),
      ],
    );

    final iconMap = await repository.fetchIconMap();

    expect(iconMap, hasLength(3));
    expect(iconMap['寺庙'], 'M10 20...');
    expect(iconMap['塔'], 'M12 18...');
    expect(iconMap['园林'], 'M14 16...');
  });

  test('fetchIconMap returns empty map when fetcher yields no data', () async {
    final repository = IconRepository(
      fetcher: () async => const <IconRecord>[],
    );

    final iconMap = await repository.fetchIconMap();

    expect(iconMap, isEmpty);
  });

  test('fetchIcons propagates error from fetcher', () async {
    final repository = IconRepository(
      fetcher: () async => throw Exception('数据库连接失败'),
    );

    expect(
      () => repository.fetchIcons(),
      throwsException,
    );
  });
}
