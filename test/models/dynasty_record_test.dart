import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/dynasty_record.dart';

void main() {
  group('DynastyRecord', () {
    const fullMap = <String, dynamic>{
      'id': 1,
      'dynasty': '唐',
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final record = DynastyRecord.fromMap(fullMap);

        expect(record.id, 1);
        expect(record.dynasty, '唐');
      });

      test('handles null and missing fields gracefully', () {
        final record = DynastyRecord.fromMap({});

        expect(record.id, 0);
        expect(record.dynasty, '');
      });

      test('handles numeric id', () {
        final map = <String, dynamic>{
          'id': 42.7,
          'dynasty': '宋',
        };
        final record = DynastyRecord.fromMap(map);
        expect(record.id, 42);
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final record = DynastyRecord.fromMap(fullMap);
        final map = record.toMap();

        expect(map['id'], 1);
        expect(map['dynasty'], '唐');
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = DynastyRecord.fromMap(fullMap);
        final map = original.toMap();
        final restored = DynastyRecord.fromMap(map);
        expect(restored, original);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = DynastyRecord.fromMap(fullMap);
        final b = DynastyRecord.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id makes not equal', () {
        final a = DynastyRecord.fromMap(fullMap);
        final b = a.copyWith(id: 2);
        expect(a, isNot(equals(b)));
      });

      test('different dynasty makes not equal', () {
        final a = DynastyRecord.fromMap(fullMap);
        final b = a.copyWith(dynasty: '宋');
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-DynastyRecord', () {
        final a = DynastyRecord.fromMap(fullMap);
        expect(a, isNot(equals('not a record')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = DynastyRecord.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes id', () {
        final original = DynastyRecord.fromMap(fullMap);
        final modified = original.copyWith(id: 100);
        expect(modified.id, 100);
        expect(modified.dynasty, original.dynasty);
      });

      test('changes dynasty', () {
        final original = DynastyRecord.fromMap(fullMap);
        final modified = original.copyWith(dynasty: '明');
        expect(modified.dynasty, '明');
        expect(modified.id, original.id);
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final record = DynastyRecord.fromMap(fullMap);
        final str = record.toString();
        expect(str, contains('DynastyRecord'));
        expect(str, contains('唐'));
      });
    });
  });
}
