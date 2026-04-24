import '../models/icon_record.dart';
import 'supabase_table_repository.dart';

/// `Icons` 表仓储。
class IconRepository {
  const IconRepository({SupabaseTableRepository? tableRepository})
    : _tableRepository =
          tableRepository ?? const SupabaseTableRepository(tableName: 'Icons');

  final SupabaseTableRepository _tableRepository;

  /// 获取全部图标记录。
  Future<List<IconRecord>> fetchIcons() {
    return _tableRepository.fetchAll<IconRecord>(mapper: IconRecord.fromMap);
  }

  /// 获取类别名 → SVG 路径数据的映射。
  Future<Map<String, String>> fetchIconMap() async {
    final icons = await fetchIcons();
    return {for (final icon in icons) icon.name: icon.svg};
  }
}
