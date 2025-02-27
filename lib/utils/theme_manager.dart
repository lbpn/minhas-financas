import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'error_logger.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  static Map<String, dynamic>? _cache;

  factory ThemeManager() {
    return _instance;
  }

  ThemeManager._internal();

  static ThemeManager get instance => _instance;

  Future<void> _initCache() async {
    try {
      if (_cache == null) {
        final prefs = await SharedPreferences.getInstance();
        _cache = {
          'themeMode': prefs.getString('themeMode') ?? 'system',
          'currency': prefs.getString('currency') ?? 'BRL',
          'customPrimaryColor': prefs.getInt('customPrimaryColor'),
          'customSecondaryColor': prefs.getInt('customSecondaryColor'),
          'customIsDark': prefs.getBool('customIsDark'),
          'authEnabled': prefs.getBool('authEnabled') ?? false,
        };
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao inicializar cache do tema: $e', stackTrace);
      _cache = {
        'themeMode': 'system',
        'currency': 'BRL',
        'customPrimaryColor': null,
        'customSecondaryColor': null,
        'customIsDark': false,
        'authEnabled': false,
      }; // Fallback em caso de erro
    }
  }

  Future<String> getThemePreference() async {
    try {
      await _initCache();
      return _cache!['themeMode'] as String;
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao obter preferência de tema: $e', stackTrace);
      return 'system'; // Fallback
    }
  }

  Future<void> setThemePreference(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', themeMode);
      await _initCache();
      _cache!['themeMode'] = themeMode;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao definir preferência de tema: $e', stackTrace);
    }
  }

  Future<void> setCustomColors(
      Color? primaryColor, Color? secondaryColor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (primaryColor != null) {
        await prefs.setInt('customPrimaryColor', primaryColor.value);
        _cache!['customPrimaryColor'] = primaryColor.value;
      }
      if (secondaryColor != null) {
        await prefs.setInt('customSecondaryColor', secondaryColor.value);
        _cache!['customSecondaryColor'] = secondaryColor.value;
      }
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao definir cores personalizadas: $e', stackTrace);
    }
  }

  Future<void> setCustomIsDark(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('customIsDark', isDark);
      _cache!['customIsDark'] = isDark;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao definir modo escuro personalizado: $e', stackTrace);
    }
  }

  Color? getCustomPrimaryColor() {
    try {
      return _cache != null && _cache!['customPrimaryColor'] != null
          ? Color(_cache!['customPrimaryColor'] as int)
          : null;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao obter cor primária personalizada: $e', stackTrace);
      return null;
    }
  }

  Color? getCustomSecondaryColor() {
    try {
      return _cache != null && _cache!['customSecondaryColor'] != null
          ? Color(_cache!['customSecondaryColor'] as int)
          : null;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao obter cor secundária personalizada: $e', stackTrace);
      return null;
    }
  }

  bool? getCustomIsDark() {
    try {
      return _cache != null ? _cache!['customIsDark'] as bool? : null;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao obter modo escuro personalizado: $e', stackTrace);
      return null;
    }
  }

  Future<String> getCurrencyPreference() async {
    try {
      await _initCache();
      return _cache!['currency'] as String;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao obter preferência de moeda: $e', stackTrace);
      return 'BRL'; // Fallback
    }
  }

  String getCurrencyPreferenceSync() {
    try {
      return _cache?['currency'] as String? ?? 'BRL';
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao obter moeda sincronamente: $e', stackTrace);
      return 'BRL';
    }
  }

  Future<void> setCurrencyPreference(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', currency);
      await _initCache();
      _cache!['currency'] = currency;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao definir preferência de moeda: $e', stackTrace);
    }
  }

  Future<bool> isAuthEnabled() async {
    try {
      await _initCache();
      return _cache!['authEnabled'] as bool;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao verificar autenticação habilitada: $e', stackTrace);
      return false; // Fallback
    }
  }

  Future<void> setAuthEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('authEnabled', enabled);
      _cache!['authEnabled'] = enabled;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao definir autenticação habilitada: $e', stackTrace);
    }
  }
}
