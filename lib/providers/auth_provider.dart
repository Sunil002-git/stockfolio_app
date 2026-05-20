import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  bool _isSuperuser = false;

  String? get accessToken => _accessToken;
  bool get isSuperuser => _isSuperuser;
  bool get isLoggedIn => _accessToken != null;

  void login(Map<String, dynamic> data) {}
  void logout() {}
}
