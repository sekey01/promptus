import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/expense_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _db;

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await init();
    return _db!;
  }

  Future<Database> init() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, 'promptus.db');

    return await openDatabase(
      databasePath,
      version: 2, // Incremented version for new table
      onCreate: (db, version) async {
        // Create tasks table
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

        // Create expenses table
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
          // Add expenses table for existing users
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

  // TASK METHODS (existing)
  Future<List<Task>> getTasks() async {
    final db = await database;
    final data = await db.query(
      'tasks',
      orderBy: 'createdAt DESC',
    );
    return data.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // EXPENSE METHODS (new)
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final data = await db.query(
      'expenses',
      orderBy: 'createdAt DESC',
    );
    return data.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ANALYTICS METHODS
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM expenses GROUP BY category'
    );

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = (row['total'] as double?) ?? 0.0;
    }
    return categoryTotals;
  }

  Future<double> getMonthlyExpenses() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE createdAt >= ? AND createdAt <= ?',
        [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch]
    );
    return (result.first['total'] as double?) ?? 0.0;
  }
}