import 'package:sqflite/sqflite.dart';

const List<String> migrations = [
  // Versão 1
  '''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    type INTEGER NOT NULL,
    category TEXT NOT NULL
  )
  ''',
  // Versão 2
  'ALTER TABLE transactions ADD COLUMN isRecurring INTEGER DEFAULT 0',
  // Versão 3
  'ALTER TABLE transactions ADD COLUMN frequency TEXT',
  // Versão 4
  '''
  CREATE TABLE goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    target_amount REAL NOT NULL,
    deadline TEXT NOT NULL
  )
  '''
];

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  for (int i = oldVersion; i < newVersion; i++) {
    await db.execute(migrations[i]);
  }
}