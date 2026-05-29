import 'package:flutter/foundation.dart';

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
  final List<String> categories;

  /// 经纬度坐标，格式为 [经度, 纬度]（longitude, latitude）。
  /// 长度应为 2，不足 2 时 `longitude`/`latitude` getter 返回 null。
  final List<double> coordinates;

  /// 经度（coordinates[0]），当坐标列表为空时返回 null。
  double? get longitude => coordinates.isNotEmpty ? coordinates[0] : null;

  /// 纬度（coordinates[1]），当坐标列表长度不足 2 时返回 null。
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;

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
    required this.categories,
    required this.coordinates,
  });

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    final rawCoordinates = map['coordinates'];
    final coordinates = rawCoordinates is List
        ? rawCoordinates
              .where(
                (value) =>
                    value is num || double.tryParse(value.toString()) != null,
              )
              .map<double>(
                (value) => value is num
                    ? value.toDouble()
                    : double.parse(value.toString()),
              )
              .toList(growable: false)
        : const <double>[];

    final rawCategories = map['categories'];
    final categories = rawCategories is List
        ? rawCategories
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : rawCategories is String
        ? rawCategories
              .split(RegExp(r'[,，、;；]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return LocationRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nameModern: (map['name_modern'] ?? '').toString(),
      nameAncient: map['name_ancient']?.toString(),
      description: map['description']?.toString(),
      averageVisitDurationMin: (map['average_visit_duration_min'] as num?)
          ?.toInt(),
      address: map['address']?.toString(),
      openTime: map['open_time']?.toString(),
      closeTime: map['close_time']?.toString(),
      isArEnabled: map['is_ar_enabled'] == true,
      topic: map['Topic']?.toString() ?? map['topic']?.toString(),
      categories: categories,
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
      'categories': categories,
      'coordinates': coordinates,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRecord &&
          other.id == id &&
          other.nameModern == nameModern &&
          other.nameAncient == nameAncient &&
          other.description == description &&
          other.averageVisitDurationMin == averageVisitDurationMin &&
          other.address == address &&
          other.openTime == openTime &&
          other.closeTime == closeTime &&
          other.isArEnabled == isArEnabled &&
          other.topic == topic &&
          listEquals(other.categories, categories) &&
          listEquals(other.coordinates, coordinates);

  @override
  int get hashCode => Object.hash(
        id,
        nameModern,
        nameAncient,
        description,
        averageVisitDurationMin,
        address,
        openTime,
        closeTime,
        isArEnabled,
        topic,
        Object.hashAll(categories),
        Object.hashAll(coordinates),
      );

  LocationRecord copyWith({
    int? id,
    String? nameModern,
    String? nameAncient,
    String? description,
    int? averageVisitDurationMin,
    String? address,
    String? openTime,
    String? closeTime,
    bool? isArEnabled,
    String? topic,
    List<String>? categories,
    List<double>? coordinates,
  }) =>
      LocationRecord(
        id: id ?? this.id,
        nameModern: nameModern ?? this.nameModern,
        nameAncient: nameAncient ?? this.nameAncient,
        description: description ?? this.description,
        averageVisitDurationMin: averageVisitDurationMin ??
            this.averageVisitDurationMin,
        address: address ?? this.address,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        isArEnabled: isArEnabled ?? this.isArEnabled,
        topic: topic ?? this.topic,
        categories: categories ?? this.categories,
        coordinates: coordinates ?? this.coordinates,
      );

  @override
  String toString() =>
      'LocationRecord('
      'id: $id, '
      'nameModern: $nameModern, '
      'nameAncient: $nameAncient, '
      'description: $description, '
      'averageVisitDurationMin: $averageVisitDurationMin, '
      'address: $address, '
      'openTime: $openTime, '
      'closeTime: $closeTime, '
      'isArEnabled: $isArEnabled, '
      'topic: $topic, '
      'categories: $categories, '
      'coordinates: $coordinates'
      ')';
}
