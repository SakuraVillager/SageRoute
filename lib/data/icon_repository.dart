import '../models/icon_record.dart';
import 'supabase_table_repository.dart';

typedef IconFetcher = Future<List<IconRecord>> Function();

/// `Icons` 表仓储。
class IconRepository {
  const IconRepository({
    IconFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
          tableRepository ?? const SupabaseTableRepository(tableName: 'Icons');

  final IconFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  /// 获取全部图标记录。
  Future<List<IconRecord>> fetchIcons() {
    if (_fetcher != null) {
      return _fetcher();
    }
    return _tableRepository.fetchAll<IconRecord>(mapper: IconRecord.fromMap);
  }

  /// 获取类别名 → SVG 路径数据的映射。
  Future<Map<String, String>> fetchIconMap() async {
    final icons = await fetchIcons();
    return {for (final icon in icons) icon.name: icon.svg};
  }
}
