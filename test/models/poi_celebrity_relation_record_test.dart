import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/poi_celebrity_relation_record.dart';

void main() {
  group('PoiCelebrityRelationRecord', () {
    const fullMap = <String, dynamic>{
      'id': 1,
      'created_at': '2024-01-15T10:30:00.000',
      'location_name': '大明宫',
      'celebrity_name': '李白',
      'relation_type': '居住',
      'weight': 5,
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final record = PoiCelebrityRelationRecord.fromMap(fullMap);

        expect(record.id, 1);
        expect(record.createdAt,
            equals(DateTime(2024, 1, 15, 10, 30)));
        expect(record.locationName, '大明宫');
        expect(record.celebrityName, '李白');
        expect(record.relationType, '居住');
        expect(record.weight, 5);
      });

      test('handles null and missing fields gracefully', () {
        final record = PoiCelebrityRelationRecord.fromMap({});

        expect(record.id, 0);
        expect(record.createdAt, null);
        expect(record.locationName, null);
        expect(record.celebrityName, null);
        expect(record.relationType, null);
        expect(record.weight, null);
      });

      test('handles null created_at', () {
        final map = <String, dynamic>{
          'id': 1,
          'created_at': null,
        };
        final record = PoiCelebrityRelationRecord.fromMap(map);
        expect(record.createdAt, null);
      });

      test('handles invalid created_at string', () {
        final map = <String, dynamic>{
          'id': 1,
          'created_at': 'not-a-date',
        };
        final record = PoiCelebrityRelationRecord.fromMap(map);
        expect(record.createdAt, null);
      });

      test('handles numeric id', () {
        final map = <String, dynamic>{
          'id': 42.3,
        };
        final record = PoiCelebrityRelationRecord.fromMap(map);
        expect(record.id, 42);
      });

      test('handles numeric weight', () {
        final map = <String, dynamic>{
          'id': 1,
          'weight': 10.9,
        };
        final record = PoiCelebrityRelationRecord.fromMap(map);
        expect(record.weight, 10);
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final record = PoiCelebrityRelationRecord.fromMap(fullMap);
        final map = record.toMap();

        expect(map['id'], 1);
        expect(map['created_at'], '2024-01-15T10:30:00.000');
        expect(map['location_name'], '大明宫');
        expect(map['celebrity_name'], '李白');
        expect(map['relation_type'], '居住');
        expect(map['weight'], 5);
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final map = original.toMap();
        final restored = PoiCelebrityRelationRecord.fromMap(map);
        expect(restored, original);
      });

      test('toMap handles null createdAt', () {
        final record = PoiCelebrityRelationRecord.fromMap({
          'id': 1,
        });
        final map = record.toMap();
        expect(map['created_at'], null);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = PoiCelebrityRelationRecord.fromMap(fullMap);
        final b = PoiCelebrityRelationRecord.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id makes not equal', () {
        final a = PoiCelebrityRelationRecord.fromMap(fullMap);
        final b = a.copyWith(id: 2);
        expect(a, isNot(equals(b)));
      });

      test('different locationName makes not equal', () {
        final a = PoiCelebrityRelationRecord.fromMap(fullMap);
        final b = a.copyWith(locationName: '华清宫');
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-PoiCelebrityRelationRecord', () {
        final a = PoiCelebrityRelationRecord.fromMap(fullMap);
        expect(a, isNot(equals('not a record')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes id', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final modified = original.copyWith(id: 100);
        expect(modified.id, 100);
        expect(modified.celebrityName, original.celebrityName);
      });

      test('changes createdAt', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final newDate = DateTime(2025, 6);
        final modified = original.copyWith(createdAt: newDate);
        expect(modified.createdAt, newDate);
      });

      test('changes locationName', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final modified = original.copyWith(locationName: '华清宫');
        expect(modified.locationName, '华清宫');
        expect(modified.id, original.id);
      });

      test('changes weight', () {
        final original = PoiCelebrityRelationRecord.fromMap(fullMap);
        final modified = original.copyWith(weight: 10);
        expect(modified.weight, 10);
        expect(modified.relationType, original.relationType);
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final record = PoiCelebrityRelationRecord.fromMap(fullMap);
        final str = record.toString();
        expect(str, contains('PoiCelebrityRelationRecord'));
        expect(str, contains('李白'));
      });
    });
  });
}
