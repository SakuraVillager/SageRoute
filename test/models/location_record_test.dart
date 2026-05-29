import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/location_record.dart';

void main() {
  group('LocationRecord', () {
    const fullMap = <String, dynamic>{
      'id': 1,
      'name_modern': '大明宫国家遗址公园',
      'name_ancient': '大明宫',
      'description': '唐朝皇宫遗址',
      'average_visit_duration_min': 120,
      'address': '陕西省西安市新城区',
      'open_time': '08:30',
      'close_time': '18:00',
      'is_ar_enabled': true,
      'topic': '唐朝',
      'categories': ['古迹', '宫殿'],
      'coordinates': [108.959, 34.292],
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final record = LocationRecord.fromMap(fullMap);

        expect(record.id, 1);
        expect(record.nameModern, '大明宫国家遗址公园');
        expect(record.nameAncient, '大明宫');
        expect(record.description, '唐朝皇宫遗址');
        expect(record.averageVisitDurationMin, 120);
        expect(record.address, '陕西省西安市新城区');
        expect(record.openTime, '08:30');
        expect(record.closeTime, '18:00');
        expect(record.isArEnabled, true);
        expect(record.topic, '唐朝');
        expect(record.categories, ['古迹', '宫殿']);
        expect(record.coordinates, [108.959, 34.292]);
        expect(record.longitude, 108.959);
        expect(record.latitude, 34.292);
      });

      test('handles missing optional fields gracefully', () {
        final record = LocationRecord.fromMap({});

        expect(record.id, 0);
        expect(record.nameModern, '');
        expect(record.nameAncient, null);
        expect(record.description, null);
        expect(record.averageVisitDurationMin, null);
        expect(record.address, null);
        expect(record.openTime, null);
        expect(record.closeTime, null);
        expect(record.isArEnabled, false);
        expect(record.topic, null);
        expect(record.categories, <String>[]);
        expect(record.coordinates, <double>[]);
        expect(record.longitude, null);
        expect(record.latitude, null);
      });

      test('handles null coordinates', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'coordinates': null,
        };
        final record = LocationRecord.fromMap(map);
        expect(record.coordinates, <double>[]);
      });

      test('parses categories from comma-separated string', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'categories': '古迹,宫殿,遗址',
          'coordinates': [],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.categories, ['古迹', '宫殿', '遗址']);
      });

      test('parses categories using Chinese and other delimiters', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'categories': '古迹、宫殿;遗址；园林',
          'coordinates': [],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.categories, ['古迹', '宫殿', '遗址', '园林']);
      });

      test('handles numeric coordinates as strings', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'coordinates': ['108.959', '34.292'],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.coordinates, [108.959, 34.292]);
      });

      test('handles empty coordinates list', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'coordinates': <double>[],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.coordinates, <double>[]);
        expect(record.longitude, null);
        expect(record.latitude, null);
      });

      test('handles coordinates with only one element', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'coordinates': [108.959],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.longitude, 108.959);
        expect(record.latitude, null);
      });

      test('handles topic with uppercase Topic key', () {
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'Topic': '唐朝',
          'coordinates': [],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.topic, '唐朝');
      });

      test('prefers uppercase Topic over lowercase topic', () {
        // The implementation checks map['Topic'] first, then falls back to map['topic'].
        final map = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'Topic': 'uppercase',
          'topic': 'lowercase',
          'coordinates': [],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.topic, 'uppercase');
      });


      test('handles numeric id', () {
        final map = <String, dynamic>{
          'id': 42.5,
          'name_modern': 'test',
          'coordinates': [],
        };
        final record = LocationRecord.fromMap(map);
        expect(record.id, 42);
      });

      test('handles is_ar_enabled with truthy values', () {
        final mapTrue = <String, dynamic>{
          'id': 1,
          'name_modern': 'test',
          'is_ar_enabled': true,
          'coordinates': [],
        };
        final mapFalse = <String, dynamic>{
          'id': 2,
          'name_modern': 'test',
          'is_ar_enabled': false,
          'coordinates': [],
        };
        final mapTruthy = <String, dynamic>{
          'id': 3,
          'name_modern': 'test',
          'is_ar_enabled': 'yes',
          'coordinates': [],
        };

        expect(LocationRecord.fromMap(mapTrue).isArEnabled, true);
        expect(LocationRecord.fromMap(mapFalse).isArEnabled, false);
        // Non-bool values should be false since we use == true
        expect(LocationRecord.fromMap(mapTruthy).isArEnabled, false);
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final record = LocationRecord.fromMap(fullMap);
        final map = record.toMap();

        expect(map['id'], 1);
        expect(map['name_modern'], '大明宫国家遗址公园');
        expect(map['name_ancient'], '大明宫');
        expect(map['description'], '唐朝皇宫遗址');
        expect(map['average_visit_duration_min'], 120);
        expect(map['address'], '陕西省西安市新城区');
        expect(map['open_time'], '08:30');
        expect(map['close_time'], '18:00');
        expect(map['is_ar_enabled'], true);
        expect(map['Topic'], '唐朝');
        expect(map['categories'], ['古迹', '宫殿']);
        expect(map['coordinates'], [108.959, 34.292]);
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = LocationRecord.fromMap(fullMap);
        final map = original.toMap();
        final restored = LocationRecord.fromMap(map);
        expect(restored, original);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = LocationRecord.fromMap(fullMap);
        final b = LocationRecord.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id makes not equal', () {
        final a = LocationRecord.fromMap(fullMap);
        final b = a.copyWith(id: 2);
        expect(a, isNot(equals(b)));
      });

      test('different categories makes not equal', () {
        final a = LocationRecord.fromMap(fullMap);
        final b = a.copyWith(categories: ['古迹']);
        expect(a, isNot(equals(b)));
      });

      test('different coordinates makes not equal', () {
        final a = LocationRecord.fromMap(fullMap);
        final b = a.copyWith(coordinates: [0.0, 0.0]);
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-LocationRecord', () {
        final a = LocationRecord.fromMap(fullMap);
        expect(a, isNot(equals('not a record')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = LocationRecord.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes nameModern', () {
        final original = LocationRecord.fromMap(fullMap);
        final modified = original.copyWith(nameModern: '华清宫');
        expect(modified.nameModern, '华清宫');
        expect(modified.id, original.id);
      });

      test('changes coordinates', () {
        final original = LocationRecord.fromMap(fullMap);
        final modified = original.copyWith(coordinates: [100.0, 50.0]);
        expect(modified.coordinates, [100.0, 50.0]);
        expect(modified.longitude, 100.0);
        expect(modified.latitude, 50.0);
      });

      test('changes isArEnabled', () {
        final original = LocationRecord.fromMap(fullMap);
        final modified = original.copyWith(isArEnabled: false);
        expect(modified.isArEnabled, false);
      });

      test('does not mutate original lists', () {
        final original = LocationRecord.fromMap(fullMap);
        final modified = original.copyWith(categories: ['新类别']);
        expect(original.categories, ['古迹', '宫殿']);
        expect(modified.categories, ['新类别']);
      });
    });

    group('longitude/latitude getters', () {
      test('return null when coordinates is empty', () {
        final record = LocationRecord.fromMap({
          'id': 1,
          'name_modern': 'test',
          'coordinates': [],
        });
        expect(record.longitude, null);
        expect(record.latitude, null);
      });

      test('return longitude but null latitude for single-element list', () {
        final record = LocationRecord.fromMap({
          'id': 1,
          'name_modern': 'test',
          'coordinates': [10.0],
        });
        expect(record.longitude, 10.0);
        expect(record.latitude, null);
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final record = LocationRecord.fromMap(fullMap);
        final str = record.toString();
        expect(str, contains('LocationRecord'));
        expect(str, contains('大明宫国家遗址公园'));
      });
    });
  });
}
