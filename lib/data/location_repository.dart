import '../models/location_record.dart';
import 'supabase_table_repository.dart';

typedef LocationFetcher = Future<List<LocationRecord>> Function();

/// `Location` 表仓储。
class LocationRepository {
  const LocationRepository({
    LocationFetcher? fetcher,
    SupabaseTableRepository? tableRepository,
    SupabaseTableRepository? topicLocationsRepository,
  }) : _fetcher = fetcher,
       _tableRepository =
           tableRepository ??
           const SupabaseTableRepository(tableName: 'Location'),
       _topicLocationsRepository =
           topicLocationsRepository ??
           const SupabaseTableRepository(tableName: 'route_topic_locations');

  final LocationFetcher? _fetcher;
  final SupabaseTableRepository _tableRepository;
  final SupabaseTableRepository _topicLocationsRepository;

  Future<LocationRecord?> fetchById(int id) async {
    final fetcher = _fetcher;
    if (fetcher != null) {
      for (final record in await fetcher()) {
        if (record.id == id) return record;
      }
      return null;
    }
    final records = await _tableRepository.fetchAll<LocationRecord>(
      mapper: LocationRecord.fromMap,
      equals: {'id (PK)': id},
      limit: 1,
    );
    return records.isEmpty ? null : records.first;
  }

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

  /// A place can belong to multiple editorial routes without duplicating it.
  Future<List<LocationRecord>> fetchLocationsByTopic(String topicName) {
    return _topicLocationsRepository.fetchAll<LocationRecord>(
      mapper: LocationRecord.fromMap,
      equals: {'theme_name': topicName},
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
