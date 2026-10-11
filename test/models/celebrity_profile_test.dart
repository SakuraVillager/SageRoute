import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/celebrity_profile.dart';

void main() {
  group('CelebrityProfile', () {
    const fullMap = <String, dynamic>{
      'id': 1,
      'name': '李白',
      'dynasty': '唐',
      'bio_short': '唐代诗人',
      'bio_full': '李白（701年－762年），字太白，号青莲居士。',
      'avatar_url': 'https://example.com/avatar.png',
      'topic': ['唐诗', '酒'],
    };

    group('fromMap', () {
      test('parses full map correctly', () {
        final profile = CelebrityProfile.fromMap(fullMap);

        expect(profile.id, 1);
        expect(profile.name, '李白');
        expect(profile.dynasty, '唐');
        expect(profile.bioShort, '唐代诗人');
        expect(profile.bioFull,
            '李白（701年－762年），字太白，号青莲居士。');
        expect(profile.avatarUrl, 'https://example.com/avatar.png');
        expect(profile.topic, ['唐诗', '酒']);
      });

      test('handles bio_full fallback from bio_ful', () {
        final map = <String, dynamic>{
          'id': 2,
          'name': '杜甫',
          'dynasty': '唐',
          'bio_short': '唐代诗人',
          'bio_ful': '杜甫（712年－770年），字子美。',
          'avatar_url': 'https://example.com/dufu.png',
          'topic': ['唐诗', '现实'],
        };
        final profile = CelebrityProfile.fromMap(map);
        expect(profile.bioFull, '杜甫（712年－770年），字子美。');
      });

      test('handles null and missing fields gracefully', () {
        final profile = CelebrityProfile.fromMap({});

        expect(profile.id, 0);
        expect(profile.name, '');
        expect(profile.dynasty, '');
        expect(profile.bioShort, '');
        expect(profile.bioFull, '');
        expect(profile.avatarUrl, '');
        expect(profile.topic, <String>[]);
      });

      test('handles null topic', () {
        final map = <String, dynamic>{
          'id': 1,
          'name': 'test',
          'dynasty': 'test',
          'bio_short': 'test',
          'bio_full': 'test',
          'avatar_url': 'test',
          'topic': null,
        };
        final profile = CelebrityProfile.fromMap(map);
        expect(profile.topic, <String>[]);
      });

      test('handles non-list topic', () {
        final map = <String, dynamic>{
          'id': 1,
          'name': 'test',
          'dynasty': 'test',
          'bio_short': 'test',
          'bio_full': 'test',
          'avatar_url': 'test',
          'topic': 'not a list',
        };
        final profile = CelebrityProfile.fromMap(map);
        expect(profile.topic, <String>[]);
      });

      test('handles numeric id', () {
        final map = <String, dynamic>{
          'id': 3.5,
          'name': 'test',
          'dynasty': 'test',
          'bio_short': 'test',
          'bio_full': 'test',
          'avatar_url': 'test',
          'topic': const ['a'],
        };
        final profile = CelebrityProfile.fromMap(map);
        expect(profile.id, 3);
      });
    });

    group('toMap', () {
      test('produces correct map', () {
        final profile = CelebrityProfile.fromMap(fullMap);
        final map = profile.toMap();

        expect(map['id'], 1);
        expect(map['name'], '李白');
        expect(map['dynasty'], '唐');
        expect(map['bio_short'], '唐代诗人');
        expect(map['bio_full'],
            '李白（701年－762年），字太白，号青莲居士。');
        expect(map['avatar_url'], 'https://example.com/avatar.png');
        expect(map['topic'], ['唐诗', '酒']);
      });

      test('roundtrip: fromMap(toMap) == original', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final map = original.toMap();
        final restored = CelebrityProfile.fromMap(map);
        expect(restored, original);
      });
    });

    group('== and hashCode', () {
      test('equal instances have same hashCode', () {
        final a = CelebrityProfile.fromMap(fullMap);
        final b = CelebrityProfile.fromMap(fullMap);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different instances are not equal', () {
        final a = CelebrityProfile.fromMap(fullMap);
        final b = a.copyWith(id: 999);
        expect(a, isNot(equals(b)));
      });

      test('is not equal to non-CelebrityProfile', () {
        final a = CelebrityProfile.fromMap(fullMap);
        expect(a, isNot(equals('not a profile')));
      });
    });

    group('copyWith', () {
      test('creates identical instance when no args', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final copy = original.copyWith();
        expect(copy, original);
      });

      test('changes id', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final modified = original.copyWith(id: 100);
        expect(modified.id, 100);
        expect(modified.name, original.name);
      });

      test('changes name', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final modified = original.copyWith(name: '杜甫');
        expect(modified.name, '杜甫');
        expect(modified.id, original.id);
      });

      test('changes topic list', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final modified = original.copyWith(topic: ['宋词']);
        expect(modified.topic, ['宋词']);
        expect(original.topic, ['唐诗', '酒']); // original unchanged
      });

      test('does not mutate original list', () {
        final original = CelebrityProfile.fromMap(fullMap);
        final modified = original.copyWith(topic: ['宋词']);
        expect(original.topic, ['唐诗', '酒']);
        expect(modified.topic, ['宋词']);
      });
    });

    group('toString', () {
      test('contains class name and key fields', () {
        final profile = CelebrityProfile.fromMap(fullMap);
        final str = profile.toString();
        expect(str, contains('CelebrityProfile'));
        expect(str, contains('李白'));
      });
    });
  });
}
