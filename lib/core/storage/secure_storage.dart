import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ─── Token ───────────────────────────────────────────────
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConfig.accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConfig.accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConfig.refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConfig.refreshTokenKey);
  }

  // ─── User Data ───────────────────────────────────────────
  static Future<void> saveUserData(String jsonStr) async {
    await _storage.write(key: AppConfig.userDataKey, value: jsonStr);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: AppConfig.userDataKey);
  }

  // ─── Clear All ───────────────────────────────────────────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
