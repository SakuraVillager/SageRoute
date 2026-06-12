import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/supabase_table_repository.dart';
import 'package:sageroute/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helpers/env_loader.dart';
import 'test_helpers/integration_test_skip.dart';

void main() {
  group('DatabaseService', () {
    setUp(() {
      DatabaseService.debugResetForTest();
    });

    test('initialize uses values loaded from assets/env.env', () async {
      String? capturedUrl;
      String? capturedKey;
      final env = loadEnvFromFile('assets/env.env');

      await DatabaseService.initialize(
        env: env,
        initializer: (url, anonKey) async {
          capturedUrl = url;
          capturedKey = anonKey;
        },
      );

      expect(capturedUrl, env['SUPABASE_URL']);
      expect(capturedKey, env['SUPABASE_ANON_KEY']);
      expect(capturedUrl, isNotEmpty);
      expect(capturedKey, isNotEmpty);
    });

    test('initialize throws when required env is missing', () async {
      expect(
        () => DatabaseService.initialize(
          env: const {'SUPABASE_URL': 'https://example.supabase.co'},
          initializer: (url, anonKey) async {},
        ),
        throwsException,
      );
    });

    test('testConnection invokes query with given table', () async {
      String? calledTable;

      await DatabaseService.testConnection(
        query: (table) async {
          calledTable = table;
          return <dynamic>[
            {'id': 1},
          ];
        },
      );

      expect(calledTable, 'Celebrity');
    });

    test('repository returns non-null field values', () async {
      final values = await _fetchSelectedFieldValues(
        table: 'Celebrity',
        field: 'name',
        query: (table, field) async {
          return <dynamic>[
            {'name': '苏东坡'},
            {'name': null},
            {'name': '白居易'},
          ];
        },
      );

      expect(values, <dynamic>['苏东坡', '白居易']);
    });

    test(
      'integration: query Supabase Celebrity table via env credentials',
      () async {
        final env = loadEnvFromFile('assets/env.env');
        final url = env['SUPABASE_URL'] ?? '';
        final anonKey = env['SUPABASE_ANON_KEY'] ?? '';

        expect(url, isNotEmpty);
        expect(anonKey, isNotEmpty);

        final client = SupabaseClient(url, anonKey);

        await DatabaseService.testConnection(
          query: (table) => client.from(table).select().limit(1),
        );

        final names = await _fetchSelectedFieldValues(
          table: 'Celebrity',
          field: 'name',
          query: (table, field) => client.from(table).select(field),
        );

        expect(names, isA<List<dynamic>>());
      },
      skip: supabaseIntegrationSkipReason(),
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

Future<List<Object>> _fetchSelectedFieldValues({
  required String table,
  required String field,
  required QueryFieldFn query,
}) async {
  final repository = SupabaseTableRepository(
    tableName: table,
    rawFetcher: ({required tableName, required columns, limit, equals}) {
      assert(limit == null);
      assert(equals == null);
      return query(tableName, columns);
    },
  );

  final rows = await repository.fetchAllRaw(columns: field);
  return rows
      .map<Object?>((row) => row[field])
      .whereType<Object>()
      .toList(growable: false);
}
