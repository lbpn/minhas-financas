import 'package:flutter/foundation.dart';

class AuthManager extends ChangeNotifier {
  static final AuthManager _instance = AuthManager._internal();
  bool _isAuthenticated = false;

  factory AuthManager() => _instance;

  AuthManager._internal();

  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }
}