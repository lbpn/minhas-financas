import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'error_logger.dart';
import 'format_utils.dart';

// Serviço para gerenciar notificações
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _plugin.initialize(settings);
      tz.initializeTimeZones();
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao inicializar notificações: $e', stackTrace);
    }
  }

  static Future<void> scheduleRecurringNotification(
      int id,
      String title,
      double amount,
      String frequency,
      DateTime startDate,
      BuildContext context,
      ) async {
    try {
      final tz.TZDateTime scheduledDate = _getNextOccurrence(startDate, frequency);
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'recurring_transactions',
        'Transações Recorrentes',
        channelDescription: 'Notificações para transações recorrentes',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id,
        'Transação Recorrente',
        '$title: ${FormatUtils.formatCurrency(context, amount)}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getMatchDateTimeComponents(frequency),
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao agendar notificação recorrente: $e', stackTrace);
    }
  }

  // Calcula a próxima ocorrência com base na frequência
  static tz.TZDateTime _getNextOccurrence(
      DateTime startDate, String frequency) {
    try {
      final now = DateTime.now();
      tz.TZDateTime nextDate = tz.TZDateTime.from(
          startDate.isBefore(now) ? now : startDate, tz.local);

      switch (frequency.toLowerCase()) {
        case 'diário':
          if (nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
            nextDate = nextDate.add(Duration(days: 1));
          }
          break;
        case 'semanal':
          nextDate = nextDate.add(
              Duration(days: 7 - (nextDate.weekday - startDate.weekday) % 7));
          if (nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
            nextDate = nextDate.add(Duration(days: 7));
          }
          break;
        case 'mensal':
          nextDate = tz.TZDateTime(
              tz.local, nextDate.year, nextDate.month + 1, nextDate.day);
          if (nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
            nextDate = tz.TZDateTime(
                tz.local, nextDate.year, nextDate.month + 1, nextDate.day);
          }
          break;
        case 'anual':
          nextDate = tz.TZDateTime(
              tz.local, nextDate.year + 1, nextDate.month, nextDate.day);
          if (nextDate.isBefore(tz.TZDateTime.now(tz.local))) {
            nextDate = tz.TZDateTime(
                tz.local, nextDate.year + 1, nextDate.month, nextDate.day);
          }
          break;
        default:
          throw Exception('Frequência desconhecida: $frequency');
      }
      return nextDate;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao calcular próxima ocorrência: $e', stackTrace);
      return tz.TZDateTime.now(tz.local)
          .add(Duration(days: 1)); // Fallback para próximo dia
    }
  }

  // Define a recorrência da notificação
  static DateTimeComponents _getMatchDateTimeComponents(String frequency) {
    try {
      switch (frequency.toLowerCase()) {
        case 'diário':
          return DateTimeComponents.time;
        case 'semanal':
          return DateTimeComponents.dayOfWeekAndTime;
        case 'mensal':
          return DateTimeComponents.dayOfMonthAndTime;
        case 'anual':
          return DateTimeComponents.dateAndTime;
        default:
          throw Exception('Frequência desconhecida: $frequency');
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao obter componentes de data: $e', stackTrace);
      return DateTimeComponents.time; // Fallback para diário
    }
  }
}
