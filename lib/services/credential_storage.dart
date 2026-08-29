import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 已保存的登录凭据。
class SavedCredentials {
  const SavedCredentials({
    required this.email,
    required this.password,
    required this.savedAt,
  });

  final String email;

  /// 保存的是登录时实际提交给 AuthService 的密码（已 trim）。
  final String password;

  /// 最近一次成功登录的时间，用于计算 7 天有效期。
  final DateTime savedAt;
}

typedef CredentialRead = Future<String?> Function(String key);

typedef CredentialWrite = Future<void> Function(String key, String value);

typedef CredentialDelete = Future<void> Function(String key);

/// 「记住密码」本地存储。
///
/// 同一台设备上，用户 7 天内成功登录过一次，[LoginPage] 就会自动填充
/// 邮箱与密码；每次成功登录都会刷新时间戳，超过 7 天后数据自动清除。
///
/// 安全性说明：当前后端为 shared_preferences（与本项目保存 Supabase
/// 会话的方式一致），密码经 base64 混淆后存储，并非加密，root /
/// 备份导出场景可被还原。如需更强的保护，可将默认后端替换为
/// flutter_secure_storage（Android Keystore / iOS Keychain），
/// 对外接口无需改动。
///
/// 所有读写方法都可通过构造参数注入，便于单元测试。
class CredentialStorage {
  CredentialStorage({
    CredentialRead? read,
    CredentialWrite? write,
    CredentialDelete? delete,
    DateTime Function()? now,
  }) : _read = read ?? _readFromPreferences,
       _write = write ?? _writeToPreferences,
       _delete = delete ?? _deleteFromPreferences,
       _now = now ?? DateTime.now;

  /// 凭据有效期：7 天内登录过即可自动填充。
  static const Duration validity = Duration(days: 7);

  /// 存储键名。与 SharedPreferences 中其他键（hasSeenOnboarding、
  /// sb-*-auth-token）互不冲突。
  static const String emailKey = 'savedLoginEmail';
  static const String passwordKey = 'savedLoginPassword';
  static const String timestampKey = 'savedLoginAt';

  final CredentialRead _read;
  final CredentialWrite _write;
  final CredentialDelete _delete;
  final DateTime Function() _now;

  static Future<String?> _readFromPreferences(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  static Future<void> _writeToPreferences(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  static Future<void> _deleteFromPreferences(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }

  /// 登录成功后调用：记住邮箱与密码，并刷新时间戳。
  Future<void> save({required String email, required String password}) async {
    await _write(emailKey, email);
    await _write(passwordKey, _encode(password));
    await _write(timestampKey, _now().millisecondsSinceEpoch.toString());
  }

  /// 读取仍在有效期内的凭据。
  ///
  /// 返回 null 的情况：从未保存、已超过 7 天（会顺带清除过期数据）、
  /// 或数据损坏（也会清除）。存储读取异常时同样返回 null，不影响登录。
  Future<SavedCredentials?> load() async {
    String? email;
    String? encodedPassword;
    String? timestampRaw;
    try {
      email = await _read(emailKey);
      encodedPassword = await _read(passwordKey);
      timestampRaw = await _read(timestampKey);
    } catch (_) {
      // 读取失败视同没有保存过，不影响登录流程。
      return null;
    }

    if (email == null || email.isEmpty || encodedPassword == null) {
      return null;
    }

    final timestamp = int.tryParse(timestampRaw ?? '');
    if (timestamp == null) {
      await _clearQuietly();
      return null;
    }
    final savedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = _now().difference(savedAt);
    if (age > validity || age.isNegative) {
      // 超过 7 天（或时间异常）-> 自动清理，不再自动填充。
      await _clearQuietly();
      return null;
    }

    final password = _decode(encodedPassword);
    if (password == null || password.isEmpty) {
      await _clearQuietly();
      return null;
    }

    return SavedCredentials(email: email, password: password, savedAt: savedAt);
  }

  /// 清除已保存的凭据。
  Future<void> clear() async {
    await _delete(emailKey);
    await _delete(passwordKey);
    await _delete(timestampKey);
  }

  /// 密码重置成功后调用：若本设备记住的正是该邮箱，则同步为新密码。
  ///
  /// 邮箱不匹配或未保存过时不做任何事（时间戳保持不变，7 天窗口
  /// 仍从最近一次登录算起）。
  Future<void> replacePassword({
    required String email,
    required String newPassword,
  }) async {
    final savedEmail = await _read(emailKey);
    if (savedEmail == null || savedEmail != email) return;
    await _write(passwordKey, _encode(newPassword));
  }

  /// 数据过期或损坏时的清理，清理失败不影响调用方。
  Future<void> _clearQuietly() async {
    try {
      await clear();
    } catch (_) {
      // ignore: 清理失败时数据到不了有效读取路径，可安全忽略。
    }
  }

  static String _encode(String value) => base64Encode(utf8.encode(value));

  static String? _decode(String value) {
    try {
      return utf8.decode(base64Decode(value));
    } catch (_) {
      return null;
    }
  }
}
