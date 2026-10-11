import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/topic_record.dart';

void main() {
  group('TopicRecord', () {
    const fullMap = <String, dynamic>{
      'id': 1,
      'created_at': '2024-03-01T08:00:00.000',
      'celebrity': '李白',
      'name': '唐诗',
      'description': '唐代诗歌的巅峰',
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final record = TopicRecord.fromMap(fullMap);

        expect(record.id, 1);
        expect(record.createdAt,
            equals(DateTime(2024, 3, 1, 8)));
        expect(record.celebrity, '李白');
        expect(record.name, '唐诗');
        expect(record.description, '唐代诗歌的巅峰');
      });

      test('handles null and missing fields gracefully', () {
        final record = TopicRecord.fromMap({});

        expect(record.id, 0);
        expect(record.createdAt, null);
        expect(record.celebrity, null);
        expect(record.name, '');
        expect(record.description, null);
      });

      test('handles null created_at', () {
        final map = <String, dynamic>{
          'id': 1,
          'name': 'topic',
          'created_at': null,
        };
        final record = TopicRecord.fromMap(map);
        expect(record.createdAt, null);
      });

      test('handles invalid created_at string', () {
        final map = <String, dynamic>{
          'id': 1,
          'name': 'topic',
          'created_at': 'not-a-date',
        };
        final record = TopicRecord.fromMap(map);
        expect(record.createdAt, null);
      });

      test('handles numeric id', () {
        final map = <String, dynamic>{
          'id': 99.9,
          'name': 'topic',
        };
        final record = TopicRecord.fromMap(map);
        expect(record.id, 99);
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final record = TopicRecord.fromMap(fullMap);
        final map = record.toMap();

        expect(map['id'], 1);
        expect(map['created_at'], '2024-03-01T08:00:00.000');
        expect(map['celebrity'], '李白');
        expect(map['name'], '唐诗');
        expect(map['description'], '唐代诗歌的巅峰');
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = TopicRecord.fromMap(fullMap);
        final map = original.toMap();
        final restored = TopicRecord.fromMap(map);
        expect(restored, original);
      });

      test('toMap handles null createdAt', () {
        final record = TopicRecord.fromMap({
          'id': 1,
          'name': 'topic',
        });
        final map = record.toMap();
        expect(map['created_at'], null);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = TopicRecord.fromMap(fullMap);
        final b = TopicRecord.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id makes not equal', () {
        final a = TopicRecord.fromMap(fullMap);
        final b = a.copyWith(id: 2);
        expect(a, isNot(equals(b)));
      });

      test('different name makes not equal', () {
        final a = TopicRecord.fromMap(fullMap);
        final b = a.copyWith(name: '宋词');
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-TopicRecord', () {
        final a = TopicRecord.fromMap(fullMap);
        expect(a, isNot(equals('not a record')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = TopicRecord.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes id', () {
        final original = TopicRecord.fromMap(fullMap);
        final modified = original.copyWith(id: 100);
        expect(modified.id, 100);
        expect(modified.name, original.name);
      });

      test('changes name', () {
        final original = TopicRecord.fromMap(fullMap);
        final modified = original.copyWith(name: '宋词');
        expect(modified.name, '宋词');
        expect(modified.id, original.id);
      });

      test('changes createdAt', () {
        final original = TopicRecord.fromMap(fullMap);
        final newDate = DateTime(2025, 6);
        final modified = original.copyWith(createdAt: newDate);
        expect(modified.createdAt, newDate);
      });

      test('changes description', () {
        final original = TopicRecord.fromMap(fullMap);
        final modified = original.copyWith(
          description: '宋代文学的代表',
        );
        expect(modified.description, '宋代文学的代表');
        expect(modified.name, original.name);
      });

      test('changes celebrity', () {
        final original = TopicRecord.fromMap(fullMap);
        final modified = original.copyWith(celebrity: '苏轼');
        expect(modified.celebrity, '苏轼');
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final record = TopicRecord.fromMap(fullMap);
        final str = record.toString();
        expect(str, contains('TopicRecord'));
        expect(str, contains('唐诗'));
      });
    });
  });
}
