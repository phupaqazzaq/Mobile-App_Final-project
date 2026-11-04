import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

/// Reads and writes expenses in the local SQLite database (spendwise.db).
///
/// This class is a singleton: its constructor is private, so the only object
/// is [DatabaseHelper.instance] and the whole app shares one open database.
class DatabaseHelper {
  DatabaseHelper._();

  /// The one shared instance, e.g. `DatabaseHelper.instance.getExpenses()`.
  static final DatabaseHelper instance = DatabaseHelper._();

  // Opened the first time it is needed, then reused.
  Future<Database>? _database;

  /// Returns the open database, opening it on first use.
  Future<Database> get database => _database ??= _openDatabase();

  /// Opens spendwise.db in the app's database folder. On the first launch the
  /// file doesn't exist yet, so sqflite creates it and calls [_onCreate].
  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'spendwise.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Creates the expenses table. Runs only once, when the file is new.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  /// Adds an expense and returns its row id.
  /// If the expense has no id, SQLite creates a new one (AUTOINCREMENT).
  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', e.toMap());
  }

  /// Returns expenses sorted newest first (by date, then by id).
  /// If [category] is given, only expenses in that category are returned.
  Future<List<Expense>> getExpenses({String? category}) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where: category == null ? null : 'category = ?',
      whereArgs: category == null ? null : [category],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  /// Saves the changes to an existing expense, found by its id.
  /// Returns the number of rows changed (1 if it worked).
  Future<int> updateExpense(Expense e) async {
    final db = await database;
    return db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  /// Deletes the expense with this [id].
  /// Returns the number of rows deleted (1 if it worked).
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the total amount spent in the month that contains [month].
  Future<double> getMonthlyTotal(DateTime month) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE date >= ? AND date < ?',
      _monthRange(month),
    );
    // SUM() returns NULL when the month has no expenses, so use 0 instead.
    final total = result.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  /// Returns how much was spent in each category in the month that contains
  /// [month], biggest first, e.g. {'Food': 850.0, 'Transport': 120.0}.
  /// Categories with no expenses that month are left out.
  Future<Map<String, double>> getCategoryTotals(DateTime month) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM expenses
      WHERE date >= ? AND date < ?
      GROUP BY category
      ORDER BY total DESC
    ''', _monthRange(month));
    return {
      for (final row in rows)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  /// The two query arguments that select one month: the first moment of the
  /// month and the first moment of the next month, as ISO 8601 strings.
  /// ISO strings sort in date order, so `date >= start AND date < end` works.
  List<String> _monthRange(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    // Month 13 is fine: DateTime turns it into January of the next year.
    final end = DateTime(month.year, month.month + 1, 1);
    return [start.toIso8601String(), end.toIso8601String()];
  }
}
