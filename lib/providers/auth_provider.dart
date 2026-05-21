import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  bool _isSuperuser = false;
  String? _username;
  bool _isInitialized = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isSuperuser => _isSuperuser;
  String? get username => _username;
  bool get isLoggedIn => _accessToken != null;
  bool get isInitialized => _isInitialized;

  Future<void> restoreSession() async {
    final access = await StorageService.getAccessToken();
    final refresh = await StorageService.getRefreshToken();
    final admin = await StorageService.getIsSuperuser();

    if (access != null && refresh != null) {
      _accessToken = access;
      _refreshToken = refresh;
      _isSuperuser = admin;
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Called after successful POST /api/login/ ─────────────────
  Future<void> login(Map<String, dynamic> response) async {
    _accessToken = response["access"] as String;
    _refreshToken = response["refresh"] as String;
    _isSuperuser = response["is_superuser"] as bool ?? false;
    _username = response["username"] as String?;
    // Persist to device storage so session survives app restart
    await StorageService.saveTokens(
      access: _accessToken!,
      refresh: _refreshToken!,
      isSuperuser: _isSuperuser,
    );
    notifyListeners();
  }

  // ── Called by Dio interceptor after silent token refresh ──────
  Future<void> updateAccessToken(String newToken) async {
    _accessToken = newToken;
    await StorageService.updateAccessToken(newToken);
    notifyListeners();
  }

  // ── Called from logout button
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _isSuperuser = false;
    _username = null;
    await StorageService.clearAll();
    notifyListeners();
  }
}
