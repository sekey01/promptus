import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/expense_model.dart';

class DatabaseService extends ChangeNotifier {
  // Singleton instance (so the same DB is used everywhere)
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _db;

  // Private constructor
  DatabaseService._internal();

  // Internal caches (to trigger UI updates on change)
  List<Task> _tasks = [];
  List<Expense> _expenses = [];

  // Getters to expose data
  List<Task> get tasks => _tasks;
  List<Expense> get expenses => _expenses;

  // Database getter
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  // Initialize database
  Future<Database> _init() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'promptus.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            reminderTime INTEGER,
            priority INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            priority INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              priority INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }
      },
    );
  }

  // ───────────────────────────────
  // TASK METHODS
  // ───────────────────────────────

  Future<void> loadTasks() async {
    final db = await database;
    final data = await db.query('tasks', orderBy: 'createdAt DESC');
    _tasks = data.map((e) => Task.fromMap(e)).toList();
    notifyListeners();
  }

  Future addTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    await loadTasks();
    notifyListeners();
    return task.id;
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    await loadTasks();
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await loadTasks();
    notifyListeners();
  }

  // ───────────────────────────────
  // EXPENSE METHODS
  // ───────────────────────────────

  Future loadExpenses() async {
    final db = await database;
    final data = await db.query('expenses', orderBy: 'createdAt DESC');
    _expenses = data.map((e) => Expense.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap());
    await loadExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await loadExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await loadExpenses();
    notifyListeners();
  }

  // ───────────────────────────────
  // ANALYTICS METHODS
  // ───────────────────────────────

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as double?) ?? 0.0;

  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses GROUP BY category',
    );

    Map<String, double> map = {};
    for (var row in result) {
      map[row['category'] as String] = (row['total'] as double?) ?? 0.0;
    }
    return map;
  }

  Future<double> getMonthlyExpenses() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month + 1, 0).millisecondsSinceEpoch;

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE createdAt >= ? AND createdAt <= ?',
      [start, end],
    );

    return (result.first['total'] as double?) ?? 0.0;
  }

  // ───────────────────────────────
  // RESET & DELETE
  // ───────────────────────────────

  Future<void> deleteAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('expenses');
      await txn.delete('sqlite_sequence', where: "name IN ('tasks', 'expenses')");
    });
    await loadTasks();
    await loadExpenses();
    notifyListeners();
  }

  Future<void> resetDatabase() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'promptus.db');

    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    await deleteDatabase(path);
    _db = await _init();

    _tasks = [];
    _expenses = [];
    notifyListeners();
  }

  Future<Map<String, int>> getDataCounts() async {
    final db = await database;

    final taskCount = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final expenseCount = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');

    return {
      'tasks': (taskCount.first['count'] as int?) ?? 0,
      'expenses': (expenseCount.first['count'] as int?) ?? 0,
    };
  }
}
