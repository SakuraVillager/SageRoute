import '../models/location_record.dart';
import 'supabase_table_repository.dart';

typedef LocationFetcher = Future<List<LocationRecord>> Function();

/// `Location` 表仓储。
class LocationRepository {
  const LocationRepository({
    LocationFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ?? const SupabaseTableRepository(tableName: 'Location');

  final LocationFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;

  /// 获取全部地点。
  Future<List<LocationRecord>> fetchLocations({int? limit}) {
    if (_fetcher != null) {
      return _fetcher();
    }
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
