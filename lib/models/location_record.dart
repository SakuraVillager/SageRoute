/// `Location` 表模型。
/// 对应字段包含：古今地名、开放时间、AR 开关、坐标等。
class LocationRecord {
  final int id;
  final String nameModern;
  final String? nameAncient;
  final String? description;
  final int? averageVisitDurationMin;
  final String? address;
  final String? openTime;
  final String? closeTime;
  final bool isArEnabled;
  final String? topic;
  final List<double> coordinates;

  const LocationRecord({
    required this.id,
    required this.nameModern,
    required this.nameAncient,
    required this.description,
    required this.averageVisitDurationMin,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.isArEnabled,
    required this.topic,
    required this.coordinates,
  });

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    final rawCoordinates = map['coordinates'];
    final coordinates = rawCoordinates is List
        ? rawCoordinates
              .where((value) => value is num || double.tryParse(value.toString()) != null)
              .map<double>((value) => value is num ? value.toDouble() : double.parse(value.toString()))
              .toList(growable: false)
        : const <double>[];

    return LocationRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nameModern: (map['name_modern'] ?? '').toString(),
      nameAncient: map['name_ancient']?.toString(),
      description: map['description']?.toString(),
      averageVisitDurationMin: (map['average_visit_duration_min'] as num?)?.toInt(),
      address: map['address']?.toString(),
      openTime: map['open_time']?.toString(),
      closeTime: map['close_time']?.toString(),
      isArEnabled: map['is_ar_enabled'] == true,
      topic: map['Topic']?.toString() ?? map['topic']?.toString(),
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_modern': nameModern,
      'name_ancient': nameAncient,
      'description': description,
      'average_visit_duration_min': averageVisitDurationMin,
      'address': address,
      'open_time': openTime,
      'close_time': closeTime,
      'is_ar_enabled': isArEnabled,
      'Topic': topic,
      'coordinates': coordinates,
    };
  }
}
