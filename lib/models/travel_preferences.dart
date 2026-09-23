import 'package:flutter/foundation.dart';

/// 旅行节奏偏好。
enum TravelPace {
  relaxed('悠闲'),
  balanced('适中'),
  packed('紧凑');

  const TravelPace(this.label);

  final String label;

  static TravelPace fromId(String? id) => TravelPace.values.firstWhere(
    (pace) => pace.name == id,
    orElse: () => TravelPace.balanced,
  );
}

/// 常用交通方式偏好。
enum TravelTransport {
  driving('驾车'),
  walking('步行');

  const TravelTransport(this.label);

  final String label;

  static TravelTransport fromId(String? id) =>
      TravelTransport.values.firstWhere(
        (transport) => transport.name == id,
        orElse: () => TravelTransport.driving,
      );
}

/// 「我的 - 旅行偏好」的本地数据模型。
///
/// 目前仅保存在本机（SharedPreferences），接入 Supabase 后会写入
/// `profiles.preferences` jsonb 字段，见 `docs/supabase_profile_schema.md`。
@immutable
class TravelPreferences {
  const TravelPreferences({
    this.dynasties = const <String>{},
    this.themes = const <String>{},
    this.pace = TravelPace.balanced,
    this.transport = TravelTransport.driving,
  });

  /// 可选的偏好朝代，取值与 mock/数据库中的朝代名保持一致。
  static const List<String> dynastyOptions = <String>['唐', '宋', '汉', '周', '明'];

  /// 可选的偏好主题。
  static const List<String> themeOptions = <String>['诗词', '哲学', '帝王', '军事'];

  /// 默认偏好：不限定朝代 / 主题，节奏适中，驾车出行。
  static const TravelPreferences defaults = TravelPreferences();

  final Set<String> dynasties;
  final Set<String> themes;
  final TravelPace pace;
  final TravelTransport transport;

  TravelPreferences copyWith({
    Set<String>? dynasties,
    Set<String>? themes,
    TravelPace? pace,
    TravelTransport? transport,
  }) {
    return TravelPreferences(
      dynasties: dynasties ?? this.dynasties,
      themes: themes ?? this.themes,
      pace: pace ?? this.pace,
      transport: transport ?? this.transport,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dynasties': dynasties.toList(growable: false),
      'themes': themes.toList(growable: false),
      'pace': pace.name,
      'transport': transport.name,
    };
  }

  /// 宽容解析：未知 / 非法取值会被忽略，保证坏数据不会让页面崩溃。
  factory TravelPreferences.fromJson(Map<String, dynamic> json) {
    Set<String> readOptions(String key, List<String> allowed) {
      final raw = json[key];
      if (raw is! List) return const <String>{};
      return raw.whereType<String>().where(allowed.contains).toSet();
    }

    return TravelPreferences(
      dynasties: readOptions('dynasties', dynastyOptions),
      themes: readOptions('themes', themeOptions),
      pace: TravelPace.fromId(json['pace'] as String?),
      transport: TravelTransport.fromId(json['transport'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TravelPreferences &&
            setEquals(other.dynasties, dynasties) &&
            setEquals(other.themes, themes) &&
            other.pace == pace &&
            other.transport == transport;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(dynasties),
    Object.hashAllUnordered(themes),
    pace,
    transport,
  );

  @override
  String toString() =>
      'TravelPreferences(dynasties: $dynasties, themes: $themes, '
      'pace: ${pace.name}, transport: ${transport.name})';
}
