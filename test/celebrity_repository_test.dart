import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/celebrity_repository.dart';
import 'package:sageroute/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helpers/env_loader.dart';

void main() {
  setUp(() {
    DatabaseService.debugResetForTest();
  });

  test('fetchCelebrities returns rows from Supabase fetcher', () async {
    var callCount = 0;
    final repository = CelebrityRepository(
      fetcher: () async {
        callCount += 1;
        return <Map<String, dynamic>>[
          {'id': 1, 'name': '苏东坡'},
          {'id': 2, 'name': '白居易'},
        ];
      },
    );

    final rows = await repository.fetchCelebrities();

    expect(callCount, 1);
    expect(rows, hasLength(2));
    expect(rows.first['name'], '苏东坡');
  });

  test(
    'integration: fetchCelebrities returns rows from Supabase table',
    () async {
      final env = loadEnvFromFile('assets/env.env');
      final url = env['SUPABASE_URL'] ?? '';
      final anonKey = env['SUPABASE_ANON_KEY'] ?? '';
      expect(url, isNotEmpty);
      expect(anonKey, isNotEmpty);

      final client = SupabaseClient(url, anonKey);
      final repository = CelebrityRepository(
        fetcher: () async {
          final response = await DatabaseService.runQueryWithRetry(
            () => client.from('Celebrity').select(),
            operationName: 'test.fetchCelebrities(Celebrity)',
          );
          return response
              .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row as Map),
              )
              .toList(growable: false);
        },
      );
      final rows = await repository.fetchCelebrities();

      expect(rows, isA<List<Map<String, dynamic>>>());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
