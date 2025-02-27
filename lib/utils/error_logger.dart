import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para debugPrint

class ErrorLogger {
  static Future<void> logError(String error, [StackTrace? stackTrace]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'error': error,
        'stackTrace': stackTrace?.toString() ?? 'Nenhum stack trace disponível',
      };

      // Carregar logs existentes
      final logsJson = prefs.getString('error_logs');
      final List<Map<String, dynamic>> logs = logsJson != null
          ? List<Map<String, dynamic>>.from(jsonDecode(logsJson))
          : [];

      // Adicionar novo log
      logs.add(logEntry);

      // Limitar a 100 logs para evitar excesso de armazenamento
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }

      // Salvar de volta
      await prefs.setString('error_logs', jsonEncode(logs));
      if (kDebugMode) {
        debugPrint(
            'Erro registrado: $error\nStackTrace: ${stackTrace ?? "Nenhum"}');
      }
    } catch (e, stackTrace) {
      // Evitar loop infinito: apenas logar no console se o próprio ErrorLogger falhar
      if (kDebugMode) {
        debugPrint('Erro ao registrar log: $e\nStackTrace: $stackTrace');
      }
    }
  }
}
