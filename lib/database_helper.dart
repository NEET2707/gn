import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseHelper {
  static final AppDatabaseHelper _instance = AppDatabaseHelper._();
  static Database? _database;

  AppDatabaseHelper._();

  factory AppDatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database and create tables
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create 'names' table
        await db.execute('''
          CREATE TABLE names(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');

        // Create 'transactions' table
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            type TEXT,
            amount REAL,
            particular TEXT
          )
        ''');
      },
    );
  }

  // ==========================
  // NAMES TABLE METHODS
  // ==========================

  Future<int> insertName(String name) async {
    final db = await database;
    return await db.insert(
      'names',  // Corrected table name
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteName(int id) async {
    final db = await database;

    // Delete all related records from the transactions table where particular matches the name
    await db.delete('transactions', where: 'particular = (SELECT name FROM names WHERE id = ?)', whereArgs: [id]);

    // Delete the name record itself from the names table
    await db.delete('names', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> checkNameExists(String name) async {
    final db = await database;
    final result = await db.query('names', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getNames() async {
    final db = await database;
    return await db.query('names');
  }

  // ==========================
  // TRANSACTIONS TABLE METHODS
  // ==========================

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert(
      'transactions',  // Corrected table name
      transaction,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByName(String name) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'particular = ?',
      whereArgs: [name],
    );
  }

  // ==========================
  // COMBINED DATA LOGIC
  // ==========================

  Future<List<Map<String, dynamic>>> loadNamesWithBalances() async {
    final db = await database;
    final names = await db.query('names');
    List<Map<String, dynamic>> updatedList = [];

    for (var nameData in names) {
      final transactions = await getTransactionsByName(nameData['name'].toString());

      double credit = 0.0;
      double debit = 0.0;

      for (var transaction in transactions) {
        if (transaction['type'] == 'credit') {
          credit += (transaction['amount'] as num).toDouble();
        } else if (transaction['type'] == 'debit') {
          debit += (transaction['amount'] as num).toDouble();
        }
      }

      updatedList.add({
        'id': nameData['id'],
        'name': nameData['name'],
        'credit': credit,
        'debit': debit,
        'balance': credit - debit,
      });
    }

    return updatedList;
  }

  Future<Map<String, double>> getTotalCreditDebitBalance() async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END) AS totalCredit,
      SUM(CASE WHEN type = 'debit' THEN amount ELSE 0 END) AS totalDebit
    FROM transactions
  ''');

    if (result.isNotEmpty) {
      double totalCredit = (result[0]['totalCredit'] as num?)?.toDouble() ?? 0.0;
      double totalDebit = (result[0]['totalDebit'] as num?)?.toDouble() ?? 0.0;
      double totalBalance = totalCredit - totalDebit;

      return {
        'totalCredit': totalCredit,
        'totalDebit': totalDebit,
        'totalBalance': totalBalance
      };
    }

    return {'totalCredit': 0.0, 'totalDebit': 0.0, 'totalBalance': 0.0};
  }

  // ==========================
  // DATABASE MAINTENANCE METHODS
  // ==========================

  Future<void> checkDatabaseTables() async {
    final db = await database;
    var result = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
    print('Tables in database: $result');
  }

  // Method to delete the entire database file
  Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    await deleteDatabase(path); // Correct function usage
  }
}
