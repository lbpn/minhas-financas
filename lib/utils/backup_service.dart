import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/database_helper.dart';
import 'error_logger.dart';

Future<void> initializeBackupService() async { // Alterado de void para Future<void>
  try {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(),
    );

    await service.startService();
  } catch (e, stackTrace) {
    ErrorLogger.logError('Erro ao inicializar serviço de backup: $e', stackTrace);
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final isAutoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
    if (!isAutoBackupEnabled) return;

    while (true) {
      final lastBackup = prefs.getInt('lastBackupTimestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const oneWeek = 7 * 24 * 60 * 60 * 1000;

      if (now - lastBackup >= oneWeek) {
        final dbPath = await DatabaseHelper.instance.getDatabasePath();
        final backupDir = await getExternalStorageDirectory();
        if (backupDir != null) {
          final backupPath = '${backupDir.path}/transactions_backup_${DateTime.now().toIso8601String()}.db';
          await File(dbPath).copy(backupPath);
          await prefs.setInt('lastBackupTimestamp', now);
        } else {
          throw Exception('Diretório de armazenamento externo não disponível');
        }
      }
      await Future.delayed(Duration(hours: 24));
    }
  } catch (e, stackTrace) {
    ErrorLogger.logError('Erro no serviço de backup: $e', stackTrace);
  }
}