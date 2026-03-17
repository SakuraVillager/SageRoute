/// `poi_celebrity_relatian` 表模型。
/// 说明：表名按数据库中的原始命名保留（relatian 拼写不做改动）。
class PoiCelebrityRelationRecord {
  final int id;
  final DateTime? createdAt;
  final String? locationName;
  final String? celebrityName;
  final String? relationType;
  final int? weight;

  const PoiCelebrityRelationRecord({
    required this.id,
    required this.createdAt,
    required this.locationName,
    required this.celebrityName,
    required this.relationType,
    required this.weight,
  });

  factory PoiCelebrityRelationRecord.fromMap(Map<String, dynamic> map) {
    return PoiCelebrityRelationRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      locationName: map['location_name']?.toString(),
      celebrityName: map['celebrity_name']?.toString(),
      relationType: map['relation_type']?.toString(),
      weight: (map['weight'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'location_name': locationName,
      'celebrity_name': celebrityName,
      'relation_type': relationType,
      'weight': weight,
    };
  }
}
