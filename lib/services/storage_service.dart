import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class StorageService {
  // Save after login
  static Future<void> saveTokens({
    required String access,
    required String refresh,
    bool isSuperuser = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, access);
    await prefs.setString(AppConstants.keyRefreshToken, refresh);
    await prefs.setBool(AppConstants.keyIsSuperuser, isSuperuser);
  }

  // Read Individual values
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  static Future<bool> getIsSuperuser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsSuperuser) ?? false;
  }

  // Update access token after silent refresh
  static Future<void> updateAccessToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, newToken);
  }

  // Clear everything on logout
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyIsSuperuser);
  }
}
