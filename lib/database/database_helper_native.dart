import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/payment.dart';

/// SQLite-backed implementation for native platforms (Android, iOS, Windows, Linux, macOS).
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gam3ety.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        national_id    TEXT    NOT NULL UNIQUE,
        phone          TEXT    NOT NULL,
        family_members INTEGER NOT NULL DEFAULT 1,
        monthly_salary REAL    NOT NULL DEFAULT 0,
        notes          TEXT    NOT NULL DEFAULT '',
        created_at     TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id  INTEGER NOT NULL,
        month_label  TEXT    NOT NULL,
        month        INTEGER NOT NULL,
        year         INTEGER NOT NULL,
        amount       REAL    NOT NULL,
        received     INTEGER NOT NULL DEFAULT 0,
        date         TEXT    NOT NULL,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertEmployee(Employee e) async {
    final d = await db;
    return d.insert(
      'employees',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEmployee(Employee e) async {
    final d = await db;
    return d.update('employees', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteEmployee(int id) async {
    final d = await db;
    return d.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<Employee?> getEmployee(int id) async {
    final d = await db;
    final rows = await d.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Employee.fromMap(rows.first);
  }

  Future<List<Employee>> getAllEmployees() async {
    final d = await db;
    final rows = await d.query('employees', orderBy: 'id DESC');
    return rows.map(Employee.fromMap).toList();
  }

  Future<List<Employee>> searchEmployees(String query) async {
    final d = await db;
    final q = '%$query%';
    final rows = await d.query(
      'employees',
      where: 'name LIKE ? OR national_id LIKE ?',
      whereArgs: [q, q],
      orderBy: 'name ASC',
    );
    return rows.map(Employee.fromMap).toList();
  }

  Future<Map<String, dynamic>> getEmployeesSummary() async {
    final d = await db;
    final result = await d.rawQuery('''
      SELECT 
        COUNT(*) as total_employees, 
        SUM(family_members) as total_family_members, 
        SUM(monthly_salary) as total_salaries 
      FROM employees
    ''');
    if (result.isEmpty) {
      return {
        'total_employees': 0,
        'total_family_members': 0,
        'total_salaries': 0.0,
      };
    }
    return {
      'total_employees': (result.first['total_employees'] as int?) ?? 0,
      'total_family_members':
          (result.first['total_family_members'] as int?) ?? 0,
      'total_salaries':
          (result.first['total_salaries'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<int> insertPayment(Payment p) async {
    final d = await db;
    return d.insert(
      'payments',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePayment(Payment p) async {
    final d = await db;
    return d.update('payments', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePayment(int id) async {
    final d = await db;
    return d.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payment>> getPaymentsForEmployee(int employeeId) async {
    final d = await db;
    final rows = await d.query(
      'payments',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'year DESC, month DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<double> totalReceivedForEmployee(int employeeId) async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE employee_id = ? AND received = 1',
      [employeeId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    final d = await db;
    return d.rawQuery(
      '''
      SELECT p.*, e.name AS employee_name, e.family_members
      FROM payments p
      JOIN employees e ON p.employee_id = e.id
      ORDER BY p.id DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<double> totalForMonth(int month, int year) async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE month = ? AND year = ? AND received = 1',
      [month, year],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> familiesForMonth(int month, int year) async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT COUNT(DISTINCT employee_id) as cnt FROM payments WHERE month = ? AND year = ? AND received = 1',
      [month, year],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getPendingPaymentsCount() async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT COUNT(*) as cnt FROM payments WHERE received = 0',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getMonthlyArchive({int limit = 12}) async {
    final d = await db;
    return d.rawQuery(
      '''
      SELECT month, year, month_label,
             COUNT(DISTINCT employee_id) as families,
             SUM(amount) as total_amount
      FROM payments
      GROUP BY year, month, month_label
      ORDER BY year DESC, month DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentsByMonth(
    int month,
    int year,
  ) async {
    final d = await db;
    return d.rawQuery(
      '''
      SELECT p.*, e.name AS employee_name, e.national_id,
             e.phone, e.family_members
      FROM payments p
      JOIN employees e ON p.employee_id = e.id
      WHERE p.month = ? AND p.year = ?
      ORDER BY e.name ASC
    ''',
      [month, year],
    );
  }

  // ── Backup: Export / Import ────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final d = await db;
    final employees = await d.query('employees');
    final payments = await d.query('payments');
    return {'employees': employees, 'payments': payments};
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final d = await db;
    await d.transaction((txn) async {
      // Wipe existing data (payments first due to FK)
      await txn.delete('payments');
      await txn.delete('employees');

      final employees = data['employees'] as List<dynamic>? ?? [];
      for (final empMap in employees) {
        final map = Map<String, dynamic>.from(empMap as Map);
        await txn.insert(
          'employees',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final payments = data['payments'] as List<dynamic>? ?? [];
      for (final payMap in payments) {
        final map = Map<String, dynamic>.from(payMap as Map);
        await txn.insert(
          'payments',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
