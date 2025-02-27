import 'package:flutter/foundation.dart';
import '../utils/database_helper.dart';

class GoalsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _goals = [];
  double _totalSavings = 0;

  List<Map<String, dynamic>> get goals => _goals;
  double get totalSavings => _totalSavings;

  GoalsProvider() {
    _loadGoals();
    _loadTotalSavings();
  }

  Future<void> _loadGoals() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final goals = await db.query('goals');
      _goals = goals;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Erro ao carregar metas: $e');
    }
  }

  Future<void> _loadTotalSavings() async {
    try {
      final transactions = await DatabaseHelper.instance.getTransactions(
        where: 'type = ?',
        whereArgs: [1],
      );
      double total = 0;
      for (var t in transactions) {
        total += t['amount'] as double;
      }
      _totalSavings = total;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Erro ao carregar poupança total: $e');
    }
  }

  Future<void> addOrEditGoal({
    int? id,
    required String name,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (id == null) {
      await db.insert('goals', {
        'name': name,
        'target_amount': targetAmount,
        'deadline': deadline.toIso8601String(),
      });
    } else {
      await db.update(
        'goals',
        {
          'name': name,
          'target_amount': targetAmount,
          'deadline': deadline.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await _loadGoals();
  }

  Future<void> deleteGoal(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await _loadGoals();
  }

  Future<void> refresh() async {
    await _loadGoals();
    await _loadTotalSavings();
  }
}
