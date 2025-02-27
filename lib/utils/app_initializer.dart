import 'package:flutter/material.dart';

import 'backup_service.dart';
import 'notification_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.initialize();
    initializeBackupService();
  }
}