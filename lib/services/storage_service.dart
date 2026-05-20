class StorageService {
  static Future<void> saveTokens({
    required String access,
    required String refresh,
    bool isSuperuser = false,
  }) async {}

  static Future<String?> getAccessToken() async => null;
  static Future<String?> getRefreshToken() async => null;
  static Future<bool?> getIsSuperuser() async => false;
  static Future<void> clearAll() async {}
}
