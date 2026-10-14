import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/dongpo_site_repository.dart';
import 'package:sageroute/data/supabase_table_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cloud catalog uses authoritative fields and stable appendix order',
    () async {
      final repo = DongpoSiteRepository(
        table: SupabaseTableRepository(
          tableName: 'dongpo_sites',
          rawFetcher:
              ({required tableName, required columns, limit, equals}) async => [
                {
                  'id': 16,
                  'name_modern': '苏堤',
                  'photos': [
                    {'url': 'https://example.com/sudi.jpg', 'credit': '实践团队'},
                  ],
                },
                {'id': 4, 'name_modern': '安乐坊'},
              ],
        ),
      );
      final catalog = await repo.fetchCatalog();
      expect(catalog.isLocalCopy, false);
      expect(catalog.sites.map((site) => site.id), [4, 16]);
      expect(catalog.sites.last.photos.single['credit'], '实践团队');
    },
  );

  test('cloud failure keeps all 37 source records available offline', () async {
    final repo = DongpoSiteRepository(
      table: SupabaseTableRepository(
        tableName: 'dongpo_sites',
        rawFetcher:
            ({required tableName, required columns, limit, equals}) async =>
                throw StateError('offline'),
      ),
    );
    final catalog = await repo.fetchCatalog();
    expect(catalog.isLocalCopy, true);
    expect(catalog.sites.length, 37);
    expect(catalog.sites[3].nameModern, '安乐坊');
  });
}
