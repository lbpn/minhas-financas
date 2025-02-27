import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../utils/error_logger.dart'; // Para copiar para a área de transferência

class ErrorLogScreen extends StatefulWidget {
  @override
  _ErrorLogScreenState createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  List<Map<String, dynamic>> _errorLogs = [];

  @override
  void initState() {
    super.initState();
    _loadErrorLogs();
  }

  Future<void> _loadErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString('error_logs');
      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        setState(() {
          _errorLogs = logsList
              .map((log) => Map<String, dynamic>.from(log))
              .toList()
            ..sort((a, b) => (b['timestamp'] ?? '')
                .compareTo(a['timestamp'] ?? '')); // Mais recentes primeiro
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar logs: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar logs')));
    }
  }

  Future<void> _clearErrorLogs() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Limpar Logs de Erro'),
          content: Text(
              'Deseja limpar todos os logs de erro? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Limpar')),
          ],
        ),
      );

      if (confirm ?? false) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('error_logs');
        setState(() => _errorLogs.clear());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Logs de erro limpos')));
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao limpar logs: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao limpar logs')));
    }
  }

  void _copyLogsToClipboard() {
    try {
      final logsString = _errorLogs
          .map((log) =>
              'Data: ${log['timestamp'] ?? 'Desconhecido'}\nErro: ${log['error'] ?? 'Sem descrição'}\nStack Trace: ${log['stackTrace'] ?? 'Nenhum'}\n---')
          .join('\n');
      Clipboard.setData(ClipboardData(text: logsString));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logs copiados para a área de transferência')));
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao copiar logs: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao copiar logs')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs de Erro'),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copiar Logs',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearErrorLogs,
            tooltip: 'Limpar Logs',
          ),
        ],
      ),
      body: _errorLogs.isEmpty
          ? Center(
              child: Text('Nenhum erro registrado ainda.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _errorLogs.length,
              itemBuilder: (context, index) {
                final log = _errorLogs[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data: ${log['timestamp'] ?? 'Desconhecido'}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Erro: ${log['error'] ?? 'Sem descrição'}'),
                        SizedBox(height: 8),
                        Text('Stack Trace: ${log['stackTrace'] ?? 'Nenhum'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
