import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'error_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static int _version = 1; // Versão inicial mínima

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('financa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    await _checkAndUpdateSchema();
    return await openDatabase(path, version: _version, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  // Esquema esperado (pode ser um arquivo JSON ou hardcoded)
  static const Map<String, String> _schemaDefinition = {
    'transactions': '''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type INTEGER NOT NULL,
        category TEXT NOT NULL,
        isRecurring INTEGER DEFAULT 0,
        frequency TEXT,
        installments INTEGER
      )
    ''',
    'custom_categories': '''
      CREATE TABLE custom_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        UNIQUE(name, type)
      )
    ''',
    'goals': '''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        deadline TEXT NOT NULL
      )
    '''
  };

  Future<void> _checkAndUpdateSchema() async {
    try {
      final db = await openDatabase(await getDatabasesPath() + '/financa.db', version: _version);
      final currentTables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

      // Extrai tabelas existentes
      final existingTables = currentTables.map((t) => t['name'] as String).toSet();

      // Compara com o esquema esperado
      bool schemaChanged = false;
      for (var table in _schemaDefinition.keys) {
        if (!existingTables.contains(table)) {
          schemaChanged = true;
          break;
        }
        // Verifica colunas (requer consulta PRAGMA table_info)
        final columns = await db.rawQuery('PRAGMA table_info($table)');
        final expectedSQL = _schemaDefinition[table]!;
        // Simplificação: assume mudança se tabelas novas forem adicionadas
        // Para colunas, precisaria parsear o SQL e comparar
      }

      if (schemaChanged) {
        _version++;
        await db.close();
        await _applySchemaChanges();
      } else {
        await db.close();
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao verificar schema: $e', stackTrace);
    }
  }

  Future<void> _applySchemaChanges() async {
    final db = await openDatabase(await getDatabasesPath() + '/financa.db', version: _version, onUpgrade: _onUpgrade);
    await db.close();
  }

  Future<void> _createDB(Database db, int version) async {
    for (var sql in _schemaDefinition.values) {
      await db.execute(sql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      for (var table in _schemaDefinition.keys) {
        if (oldVersion < newVersion) {
          await db.execute(_schemaDefinition[table]!); // Cria ou atualiza tabelas
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao atualizar banco de dados: $e', stackTrace);
    }
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'financa.db');
  }

  Future<void> addTransaction(
    String title,
    double amount,
    String date,
    int type,
    String category, {
    int? isRecurring,
    String? frequency,
    int? installments,
  }) async {
    try {
      final db = await database;
      await db.insert(
        'transactions',
        {
          'title': title,
          'amount': amount,
          'date': date,
          'type': type,
          'category': category,
          'isRecurring': isRecurring ?? 0,
          'frequency': frequency,
          'installments': installments,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao adicionar transação: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> updateTransaction(
    int id,
    String title,
    double amount,
    String date,
    int type,
    String category, {
    int? isRecurring,
    String? frequency,
    int? installments,
  }) async {
    try {
      final db = await database;
      await db.update(
        'transactions',
        {
          'title': title,
          'amount': amount,
          'date': date,
          'type': type,
          'category': category,
          'isRecurring': isRecurring ?? 0,
          'frequency': frequency,
          'installments': installments,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao atualizar transação: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final db = await database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao excluir transação: $e', stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int? limit,
    int? offset,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    try {
      final db = await database;
      return await db.query(
        'transactions',
        limit: limit,
        offset: offset,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy ?? 'date DESC',
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao obter transações: $e', stackTrace);
      rethrow;
    }
  }

  Future<bool> addCustomCategory(String name, int type) async {
    try {
      final db = await database;
      final result = await db.insert(
        'custom_categories',
        {'name': name, 'type': type},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return result > 0;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao adicionar categoria personalizada: $e', stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomCategoriesWithCounts() async {
    try {
      final db = await database;
      return await db.rawQuery('''
SELECT cc.id, cc.name, cc.type, COUNT(t.id) as transaction_count
FROM custom_categories cc
LEFT JOIN transactions t ON t.category = cc.name AND t.type = cc.type
GROUP BY cc.id, cc.name, cc.type
''');
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao obter categorias personalizadas: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> updateCustomCategory(int id, String newName) async {
    try {
      final db = await database;
      await db.update(
        'custom_categories',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [id],
      );
      await db.update(
        'transactions',
        {'category': newName},
        where: 'category = (SELECT name FROM custom_categories WHERE id = ?)',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao atualizar categoria personalizada: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> deleteCustomCategory(int id) async {
    try {
      final db = await database;
      await db.delete('custom_categories', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao excluir categoria personalizada: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> exportDatabase() async {
    try {
      final dbPath = await getDatabasePath();
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = join(directory.path, 'financa_export.db');
      await File(dbPath).copy(exportPath);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao exportar banco de dados: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> importDatabase(String newDbPath) async {
    try {
      final dbPath = await getDatabasePath();
      await close();
      await File(newDbPath).copy(dbPath);
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao importar banco de dados: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao fechar banco de dados: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> deleteOldTransactions() async {
    try {
      final db = await database;
      final oneYearAgo =
          DateTime.now().subtract(Duration(days: 365)).toIso8601String();
      await db.delete(
        'transactions',
        where: 'date < ?',
        whereArgs: [oneYearAgo],
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao excluir transações antigas: $e', stackTrace);
      rethrow;
    }
  }

  Future<bool> isCategoryInUse(String categoryName) async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'category = ?',
        whereArgs: [categoryName],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao verificar uso da categoria: $e', stackTrace);
      rethrow;
    }
  }
}
