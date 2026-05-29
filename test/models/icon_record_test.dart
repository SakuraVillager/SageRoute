import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/icon_record.dart';

void main() {
  group('IconRecord', () {
    const fullMap = <String, dynamic>{
      'name': '寺庙',
      'svg': 'M10 20...',
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final record = IconRecord.fromMap(fullMap);

        expect(record.name, '寺庙');
        expect(record.svg, 'M10 20...');
      });

      test('handles SVG uppercase key fallback', () {
        final map = <String, dynamic>{
          'name': '宫殿',
          'SVG': 'M20 30...',
        };
        final record = IconRecord.fromMap(map);
        expect(record.name, '宫殿');
        expect(record.svg, 'M20 30...');
      });

      test('prefers lowercase svg over uppercase SVG', () {
        final map = <String, dynamic>{
          'name': 'test',
          'svg': 'lowercase-svg',
          'SVG': 'uppercase-svg',
        };
        final record = IconRecord.fromMap(map);
        expect(record.svg, 'lowercase-svg');
      });

      test('handles null and missing fields gracefully', () {
        final record = IconRecord.fromMap({});

        expect(record.name, '');
        expect(record.svg, '');
      });

      test('handles null svg', () {
        final map = <String, dynamic>{
          'name': 'test',
          'svg': null,
        };
        final record = IconRecord.fromMap(map);
        expect(record.name, 'test');
        expect(record.svg, '');
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final record = IconRecord.fromMap(fullMap);
        final map = record.toMap();

        expect(map['name'], '寺庙');
        expect(map['svg'], 'M10 20...');
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = IconRecord.fromMap(fullMap);
        final map = original.toMap();
        final restored = IconRecord.fromMap(map);
        expect(restored, original);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = IconRecord.fromMap(fullMap);
        final b = IconRecord.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different name makes not equal', () {
        final a = IconRecord.fromMap(fullMap);
        final b = a.copyWith(name: '宫殿');
        expect(a, isNot(equals(b)));
      });

      test('different svg makes not equal', () {
        final a = IconRecord.fromMap(fullMap);
        final b = a.copyWith(svg: 'M99 99...');
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-IconRecord', () {
        final a = IconRecord.fromMap(fullMap);
        expect(a, isNot(equals('not a record')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = IconRecord.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes name', () {
        final original = IconRecord.fromMap(fullMap);
        final modified = original.copyWith(name: '佛塔');
        expect(modified.name, '佛塔');
        expect(modified.svg, original.svg);
      });

      test('changes svg', () {
        final original = IconRecord.fromMap(fullMap);
        final modified = original.copyWith(svg: 'M5 5...');
        expect(modified.svg, 'M5 5...');
        expect(modified.name, original.name);
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final record = IconRecord.fromMap(fullMap);
        final str = record.toString();
        expect(str, contains('IconRecord'));
        expect(str, contains('寺庙'));
      });
    });
  });
}
