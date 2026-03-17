import '../models/location_record.dart';
import 'supabase_table_repository.dart';

/// `Location` 表仓储。
class LocationRepository {
  const LocationRepository({
    SupabaseTableRepository? tableRepository,
  }) : _tableRepository =
           tableRepository ?? const SupabaseTableRepository(tableName: 'Location');

  final SupabaseTableRepository _tableRepository;

  /// 获取全部地点。
  Future<List<LocationRecord>> fetchLocations({int? limit}) {
    return _tableRepository.fetchAll<LocationRecord>(
      mapper: LocationRecord.fromMap,
      limit: limit,
    );
  }

  /// 按 Topic 字段过滤地点。
  Future<List<LocationRecord>> fetchLocationsByTopic(String topicName) {
    return _tableRepository.fetchAll<LocationRecord>(
      mapper: LocationRecord.fromMap,
      equals: {'Topic': topicName},
    );
  }

  /// 获取支持 AR 的地点。
  Future<List<LocationRecord>> fetchArEnabledLocations() {
    return _tableRepository.fetchAll<LocationRecord>(
      mapper: LocationRecord.fromMap,
      equals: {'is_ar_enabled': true},
    );
  }
}
