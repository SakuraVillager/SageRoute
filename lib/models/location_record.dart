import 'package:flutter/foundation.dart';
import 'heritage_grade.dart';

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
  final String? period;
  final String? historicalEvent;
  final String? relatedLiterature;
  final String? literatureSource;
  final String? researchNotes;
  final HeritageGrade? heritageGrade;
  final int? dongpoSiteId;
  final bool? routeEligible;
  final List<String> themes;
  final String? coordinateNote;
  final List<Map<String, String>> photos;
  final bool isCoreSite;

  bool get canPlanRoute => routeEligible != false && hasValidCoordinates;

  bool get hasValidCoordinates =>
      coordinates.length == 2 &&
      coordinates.every((value) => value.isFinite) &&
      coordinates[0].abs() <= 180 &&
      coordinates[1].abs() <= 90 &&
      !(coordinates[0] == 0 && coordinates[1] == 0);

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
    this.period,
    this.historicalEvent,
    this.relatedLiterature,
    this.literatureSource,
    this.researchNotes,
    this.heritageGrade,
    this.dongpoSiteId,
    this.routeEligible,
    this.themes = const [],
    this.coordinateNote,
    this.photos = const [],
    this.isCoreSite = false,
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
      // The live Location table names its primary key "id (PK)".
      // Keep "id" as a fallback for older fixtures and data sources.
      id: (map['id (PK)'] as num? ?? map['id'] as num?)?.toInt() ?? 0,
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
      period: map['period']?.toString(),
      historicalEvent: map['historical_event']?.toString(),
      relatedLiterature: map['related_literature']?.toString(),
      literatureSource: map['literature_source']?.toString(),
      researchNotes: map['research_notes']?.toString(),
      heritageGrade: HeritageGrade.parse(map['heritage_grade']),
      routeEligible: map['route_eligible'] as bool?,
      dongpoSiteId:
          (map['dongpo_site_id'] as num?)?.toInt() ??
          int.tryParse(
            RegExp(
                  r'^dongpo-hangzhou-(\d+)$',
                ).firstMatch(map['catalog_key']?.toString() ?? '')?.group(1) ??
                '',
          ),
      themes: map['themes'] is List
          ? (map['themes'] as List)
                .map((value) => value.toString())
                .toList(growable: false)
          : const [],
      coordinateNote: map['coordinate_note']?.toString(),
      photos: map['photos'] is List
          ? (map['photos'] as List)
                .whereType<Map>()
                .map(
                  (photo) => photo.map(
                    (key, value) =>
                        MapEntry(key.toString(), value?.toString() ?? ''),
                  ),
                )
                .toList(growable: false)
          : const [],
      isCoreSite: map['is_core_site'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id (PK)': id,
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
      if (period != null) 'period': period,
      if (historicalEvent != null) 'historical_event': historicalEvent,
      if (relatedLiterature != null) 'related_literature': relatedLiterature,
      if (literatureSource != null) 'literature_source': literatureSource,
      if (researchNotes != null) 'research_notes': researchNotes,
      if (heritageGrade != null) 'heritage_grade': heritageGrade!.label,
      if (dongpoSiteId != null) 'dongpo_site_id': dongpoSiteId,
      if (routeEligible != null) 'route_eligible': routeEligible,
      if (themes.isNotEmpty) 'themes': themes,
      if (coordinateNote != null) 'coordinate_note': coordinateNote,
      if (photos.isNotEmpty) 'photos': photos,
      if (isCoreSite) 'is_core_site': isCoreSite,
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
          listEquals(other.coordinates, coordinates) &&
          other.period == period &&
          other.historicalEvent == historicalEvent &&
          other.relatedLiterature == relatedLiterature &&
          other.literatureSource == literatureSource &&
          other.researchNotes == researchNotes &&
          other.heritageGrade == heritageGrade &&
          other.dongpoSiteId == dongpoSiteId &&
          other.routeEligible == routeEligible &&
          other.coordinateNote == coordinateNote &&
          other.isCoreSite == isCoreSite &&
          listEquals(other.themes, themes) &&
          photos.length == other.photos.length &&
          List.generate(
            photos.length,
            (index) => mapEquals(photos[index], other.photos[index]),
          ).every((equal) => equal);

  @override
  int get hashCode => Object.hashAll([
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
    period,
    historicalEvent,
    relatedLiterature,
    literatureSource,
    researchNotes,
    heritageGrade,
    dongpoSiteId,
    routeEligible,
    coordinateNote,
    isCoreSite,
    Object.hashAll(themes),
    Object.hashAll(
      photos.map(
        (photo) => Object.hashAllUnordered(
          photo.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      ),
    ),
  ]);

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
    String? period,
    String? historicalEvent,
    String? relatedLiterature,
    String? literatureSource,
    String? researchNotes,
    HeritageGrade? heritageGrade,
    int? dongpoSiteId,
    bool? routeEligible,
    List<String>? themes,
    String? coordinateNote,
    List<Map<String, String>>? photos,
    bool? isCoreSite,
  }) => LocationRecord(
    id: id ?? this.id,
    nameModern: nameModern ?? this.nameModern,
    nameAncient: nameAncient ?? this.nameAncient,
    description: description ?? this.description,
    averageVisitDurationMin:
        averageVisitDurationMin ?? this.averageVisitDurationMin,
    address: address ?? this.address,
    openTime: openTime ?? this.openTime,
    closeTime: closeTime ?? this.closeTime,
    isArEnabled: isArEnabled ?? this.isArEnabled,
    topic: topic ?? this.topic,
    categories: categories ?? this.categories,
    coordinates: coordinates ?? this.coordinates,
    period: period ?? this.period,
    historicalEvent: historicalEvent ?? this.historicalEvent,
    relatedLiterature: relatedLiterature ?? this.relatedLiterature,
    literatureSource: literatureSource ?? this.literatureSource,
    researchNotes: researchNotes ?? this.researchNotes,
    heritageGrade: heritageGrade ?? this.heritageGrade,
    dongpoSiteId: dongpoSiteId ?? this.dongpoSiteId,
    routeEligible: routeEligible ?? this.routeEligible,
    themes: themes ?? this.themes,
    coordinateNote: coordinateNote ?? this.coordinateNote,
    photos: photos ?? this.photos,
    isCoreSite: isCoreSite ?? this.isCoreSite,
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
