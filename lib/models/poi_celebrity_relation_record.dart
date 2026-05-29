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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoiCelebrityRelationRecord &&
          other.id == id &&
          other.createdAt == createdAt &&
          other.locationName == locationName &&
          other.celebrityName == celebrityName &&
          other.relationType == relationType &&
          other.weight == weight;

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        locationName,
        celebrityName,
        relationType,
        weight,
      );

  PoiCelebrityRelationRecord copyWith({
    int? id,
    DateTime? createdAt,
    String? locationName,
    String? celebrityName,
    String? relationType,
    int? weight,
  }) =>
      PoiCelebrityRelationRecord(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        locationName: locationName ?? this.locationName,
        celebrityName: celebrityName ?? this.celebrityName,
        relationType: relationType ?? this.relationType,
        weight: weight ?? this.weight,
      );

  @override
  String toString() =>
      'PoiCelebrityRelationRecord('
      'id: $id, '
      'createdAt: $createdAt, '
      'locationName: $locationName, '
      'celebrityName: $celebrityName, '
      'relationType: $relationType, '
      'weight: $weight'
      ')';
}
