import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: userIdKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveSessionStartTime(String requestId, int timestampMs) async {
    await _storage.write(key: 'session_start_$requestId', value: timestampMs.toString());
  }

  static Future<int?> getSessionStartTime(String requestId) async {
    final val = await _storage.read(key: 'session_start_$requestId');
    if (val != null) return int.tryParse(val);
    return null;
  }

  static Future<void> clearSessionStartTime(String requestId) async {
    await _storage.delete(key: 'session_start_$requestId');
  }
}
