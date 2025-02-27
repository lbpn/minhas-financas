import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'theme_manager.dart';

class FormatUtils {
  static String formatCurrency(BuildContext context, double value) {
    final currency = Provider.of<ThemeManager>(context, listen: false).getCurrencyPreferenceSync();
    return NumberFormat.simpleCurrency(locale: 'pt_BR', name: currency).format(value);
  }

  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'pt_BR').format(date);
  }
}