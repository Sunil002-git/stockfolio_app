// lib/core/constants.dart
// One place for values used across the whole app.
// When you deploy to production, you only change BASE_URL here.

class AppConstants {
  // Your Django backend
  // While running locally on your Windows PC with the emulator,
  // use 10.0.2.2 — the Android emulator's alias for localhost.
  // On a real device on the same WiFi, use your PC's local IP (e.g. 192.168.1.5).
  static const String baseUrl = 'http://10.0.2.2:8000/api/';
  // static const String baseUrl = 'https://stockfolio-xv8x.onrender.com/api/';

  // SharedPreferences keys - same names as localStorage keys in the web app
  static const String keyToken = 'token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyIsSuperuser = 'is_superuser';

  // App Info
  static const String appName = 'Stockfolio';
  static const String appVersion = '1.0.0';
}
