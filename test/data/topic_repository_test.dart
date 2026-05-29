import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/topic_repository.dart';
import 'package:sageroute/models/topic_record.dart';
import 'package:sageroute/services/database_service.dart';

void main() {
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchTopics returns rows from mock fetcher', () async {
    var callCount = 0;
    final repository = TopicRepository(
      fetcher: () async {
        callCount += 1;
        return const <TopicRecord>[
          TopicRecord(
            id: 1,
            createdAt: null,
            celebrity: '苏东坡',
            name: '西湖诗词',
            description: '苏东坡与西湖相关的诗词',
          ),
          TopicRecord(
            id: 2,
            createdAt: null,
            celebrity: '白居易',
            name: '钱塘湖春行',
            description: '白居易描写西湖的诗作',
          ),
          TopicRecord(
            id: 3,
            createdAt: null,
            celebrity: '苏轼',
            name: '赤壁赋',
            description: '前后赤壁赋',
          ),
        ];
      },
    );

    final rows = await repository.fetchTopics();

    expect(callCount, 1);
    expect(rows, hasLength(3));
    expect(rows.first.celebrity, '苏东坡');
    expect(rows.last.name, '赤壁赋');
  });

  test('fetchTopics with limit returns subset via fetcher', () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[
        TopicRecord(
          id: 1,
          createdAt: null,
          celebrity: '苏东坡',
          name: '西湖诗词',
          description: null,
        ),
        TopicRecord(
          id: 2,
          createdAt: null,
          celebrity: '白居易',
          name: '钱塘湖春行',
          description: null,
        ),
        TopicRecord(
          id: 3,
          createdAt: null,
          celebrity: '苏轼',
          name: '赤壁赋',
          description: null,
        ),
      ],
    );

    final rows = await repository.fetchTopics(limit: 2);

    expect(rows, hasLength(2));
    expect(rows.first.name, '西湖诗词');
    expect(rows.last.name, '钱塘湖春行');
  });

  test('fetchTopicsByCelebrity filters by celebrity name via fetcher', () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[
        TopicRecord(
          id: 1,
          createdAt: null,
          celebrity: '苏东坡',
          name: '西湖诗词',
          description: null,
        ),
        TopicRecord(
          id: 2,
          createdAt: null,
          celebrity: '苏东坡',
          name: '赤壁赋',
          description: null,
        ),
        TopicRecord(
          id: 3,
          createdAt: null,
          celebrity: '白居易',
          name: '钱塘湖春行',
          description: null,
        ),
      ],
    );

    final rows = await repository.fetchTopicsByCelebrity('苏东坡');

    expect(rows, hasLength(2));
    expect(rows.first.celebrity, '苏东坡');
    expect(rows.map((t) => t.name), containsAll(['西湖诗词', '赤壁赋']));
  });

  test('fetchTopicsByCelebrity returns empty when no match in fetcher data',
      () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[
        TopicRecord(
          id: 1,
          createdAt: null,
          celebrity: '苏东坡',
          name: '西湖诗词',
          description: null,
        ),
      ],
    );

    final rows = await repository.fetchTopicsByCelebrity('李白');

    expect(rows, isEmpty);
  });

  test('fetchTopicsByCelebrity returns empty for blank celebrity name', () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[
        TopicRecord(
          id: 1,
          createdAt: null,
          celebrity: '苏东坡',
          name: '西湖诗词',
          description: null,
        ),
      ],
    );

    final rows = await repository.fetchTopicsByCelebrity('  ');

    expect(rows, isEmpty);
  });

  test('fetchTopicsByCelebrity returns empty for empty string', () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[
        TopicRecord(
          id: 1,
          createdAt: null,
          celebrity: '苏东坡',
          name: '西湖诗词',
          description: null,
        ),
      ],
    );

    final rows = await repository.fetchTopicsByCelebrity('');

    expect(rows, isEmpty);
  });

  test('fetchTopics returns empty list when fetcher yields no data', () async {
    final repository = TopicRepository(
      fetcher: () async => const <TopicRecord>[],
    );

    final rows = await repository.fetchTopics();

    expect(rows, isEmpty);
  });

  test('fetchTopics propagates error from fetcher', () async {
    final repository = TopicRepository(
      fetcher: () async => throw Exception('查询失败'),
    );

    expect(
      () => repository.fetchTopics(),
      throwsException,
    );
  });
}
