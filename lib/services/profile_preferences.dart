import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_preferences.dart';

/// 「我的」页一次性加载出的本地资料。
@immutable
class ProfileLocalState {
  const ProfileLocalState({
    this.nickname,
    this.bio,
    this.language = ProfilePreferences.defaultLanguage,
    this.travelPreferences = TravelPreferences.defaults,
  });

  /// 本地昵称；为空表示未覆盖，展示时应回退到登录账号的昵称。
  final String? nickname;

  /// 本地个人简介；为空表示未填写。
  final String? bio;

  /// 界面语言代码。
  final String language;

  final TravelPreferences travelPreferences;
}

/// 「我的」页本地偏好存储。
///
/// Phase 1 先把昵称、简介、语言与旅行偏好保存在本机。
/// 后续接入 Supabase `profiles` / `user_*` 表后，这里会降级为离线缓存，
/// 表结构见 `docs/supabase_profile_schema.md`。
class ProfilePreferences {
  static const String nicknameKey = 'profile.nickname';
  static const String bioKey = 'profile.bio';
  static const String languageKey = 'profile.language';
  static const String travelPreferencesKey = 'profile.travel_preferences';

  static const String defaultLanguage = 'zh-Hans';
  static const String simplifiedChineseLabel = '简体中文';

  /// 已支持的界面语言。
  static const Map<String, String> supportedLanguages = <String, String>{
    defaultLanguage: simplifiedChineseLabel,
  };

  /// 规划中的界面语言（多语言化完成前只展示、不可选）。
  static const Map<String, String> upcomingLanguages = <String, String>{
    'zh-Hant': '繁體中文',
    'en': 'English',
  };

  static String labelForLanguage(String code) =>
      supportedLanguages[code] ?? upcomingLanguages[code] ?? code;

  Future<ProfileLocalState> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ProfileLocalState(
      nickname: preferences.getString(nicknameKey),
      bio: preferences.getString(bioKey),
      language: preferences.getString(languageKey) ?? defaultLanguage,
      travelPreferences: _decodeTravelPreferences(
        preferences.getString(travelPreferencesKey),
      ),
    );
  }

  /// 保存昵称；传空字符串表示清除本地覆盖，回退到账号昵称。
  Future<void> saveNickname(String nickname) async {
    final preferences = await SharedPreferences.getInstance();
    final value = nickname.trim();
    if (value.isEmpty) {
      await preferences.remove(nicknameKey);
    } else {
      await preferences.setString(nicknameKey, value);
    }
  }

  /// 保存个人简介；空字符串表示清空。
  Future<void> saveBio(String bio) async {
    final preferences = await SharedPreferences.getInstance();
    final value = bio.trim();
    if (value.isEmpty) {
      await preferences.remove(bioKey);
    } else {
      await preferences.setString(bioKey, value);
    }
  }

  /// 保存界面语言；未在 [supportedLanguages] 中的语言会被忽略。
  Future<void> saveLanguage(String code) async {
    if (!supportedLanguages.containsKey(code)) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(languageKey, code);
  }

  Future<void> saveTravelPreferences(TravelPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      travelPreferencesKey,
      jsonEncode(value.toJson()),
    );
  }

  TravelPreferences _decodeTravelPreferences(String? raw) {
    if (raw == null || raw.isEmpty) return TravelPreferences.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return TravelPreferences.fromJson(decoded);
      }
      if (decoded is Map) {
        return TravelPreferences.fromJson(
          decoded.map((key, value) => MapEntry('$key', value)),
        );
      }
    } catch (error) {
      debugPrint(
        '[ProfilePreferences] decode travel preferences failed: $error',
      );
    }
    return TravelPreferences.defaults;
  }
}
