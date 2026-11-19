import '../models/employee.dart';
import '../models/payment.dart';

/// In-memory DatabaseHelper for web platform.
/// Data is not persisted between page refreshes.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  int _empIdCounter = 0;
  int _payIdCounter = 0;
  final List<Employee> _employees = [];
  final List<Payment> _payments = [];

  // ── Employee CRUD ──────────────────────────────────────────────────────────

  Future<int> insertEmployee(Employee e) async {
    _empIdCounter++;
    final newEmp = e.copyWith(id: _empIdCounter);
    // Check unique national_id
    _employees.removeWhere((ex) => ex.nationalId == newEmp.nationalId);
    _employees.add(newEmp);
    return _empIdCounter;
  }

  Future<int> updateEmployee(Employee e) async {
    final idx = _employees.indexWhere((emp) => emp.id == e.id);
    if (idx >= 0) _employees[idx] = e;
    return 1;
  }

  Future<int> deleteEmployee(int id) async {
    _employees.removeWhere((e) => e.id == id);
    _payments.removeWhere((p) => p.employeeId == id);
    return 1;
  }

  Future<Employee?> getEmployee(int id) async {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Employee>> getAllEmployees() async =>
      List.from(_employees.reversed);

  Future<List<Employee>> searchEmployees(String query) async {
    final q = query.toLowerCase();
    return _employees
        .where(
          (e) => e.name.toLowerCase().contains(q) || e.nationalId.contains(q),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getEmployeesSummary() async {
    int totalEmployees = _employees.length;
    int totalFamilyMembers = _employees.fold(
      0,
      (sum, e) => sum + e.familyMembers,
    );
    double totalSalaries = _employees.fold(
      0.0,
      (sum, e) => sum + e.monthlySalary,
    );
    return {
      'total_employees': totalEmployees,
      'total_family_members': totalFamilyMembers,
      'total_salaries': totalSalaries,
    };
  }

  // ── Payment CRUD ───────────────────────────────────────────────────────────

  Future<int> insertPayment(Payment p) async {
    _payIdCounter++;
    _payments.add(p.copyWith(id: _payIdCounter));
    return _payIdCounter;
  }

  Future<int> updatePayment(Payment p) async {
    final idx = _payments.indexWhere((pay) => pay.id == p.id);
    if (idx >= 0) _payments[idx] = p;
    return 1;
  }

  Future<int> deletePayment(int id) async {
    _payments.removeWhere((p) => p.id == id);
    return 1;
  }

  Future<List<Payment>> getPaymentsForEmployee(int employeeId) async {
    final list = _payments.where((p) => p.employeeId == employeeId).toList();
    list.sort(
      (a, b) => b.year != a.year
          ? b.year.compareTo(a.year)
          : b.month.compareTo(a.month),
    );
    return list;
  }

  Future<double> totalReceivedForEmployee(int employeeId) async => _payments
      .where((p) => p.employeeId == employeeId && p.received)
      .fold<double>(0.0, (s, p) => s + p.amount);

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    final result = <Map<String, dynamic>>[];
    for (final p in _payments.reversed) {
      if (result.length >= limit) break;
      try {
        final e = _employees.firstWhere((e) => e.id == p.employeeId);
        result.add({
          ...p.toMap(),
          'employee_name': e.name,
          'family_members': e.familyMembers,
        });
      } catch (_) {}
    }
    return result;
  }

  Future<double> totalForMonth(int month, int year) async => _payments
      .where((p) => p.month == month && p.year == year && p.received)
      .fold<double>(0.0, (s, p) => s + p.amount);

  Future<int> familiesForMonth(int month, int year) async => _payments
      .where((p) => p.month == month && p.year == year && p.received)
      .map((p) => p.employeeId)
      .toSet()
      .length;

  Future<int> getPendingPaymentsCount() async =>
      _payments.where((p) => !p.received).length;

  Future<List<Map<String, dynamic>>> getMonthlyArchive({int limit = 12}) async {
    final archive = <String, Map<String, dynamic>>{};
    for (final p in _payments) {
      final key = '${p.year}-${p.month}';
      if (!archive.containsKey(key)) {
        archive[key] = {
          'month': p.month,
          'year': p.year,
          'month_label': p.monthLabel,
          'families': <int>{},
          'total_amount': 0.0,
        };
      }
      (archive[key]!['families'] as Set<int>).add(p.employeeId);
      archive[key]!['total_amount'] =
          (archive[key]!['total_amount'] as double) + p.amount;
    }

    final sorted = archive.values.toList()
      ..sort((a, b) {
        final aDate = DateTime(a['year'] as int, a['month'] as int);
        final bDate = DateTime(b['year'] as int, b['month'] as int);
        return bDate.compareTo(aDate);
      });

    return sorted
        .take(limit)
        .map(
          (a) => {
            'month': a['month'],
            'year': a['year'],
            'month_label': a['month_label'],
            'families': (a['families'] as Set<int>).length,
            'total_amount': a['total_amount'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPaymentsByMonth(
    int month,
    int year,
  ) async {
    final list = _payments
        .where((p) => p.month == month && p.year == year)
        .toList();
    final result = <Map<String, dynamic>>[];
    for (final p in list) {
      try {
        final e = _employees.firstWhere((e) => e.id == p.employeeId);
        result.add({
          ...p.toMap(),
          'employee_name': e.name,
          'national_id': e.nationalId,
          'phone': e.phone,
          'family_members': e.familyMembers,
        });
      } catch (_) {}
    }
    result.sort(
      (a, b) => (a['employee_name'] as String).compareTo(
        b['employee_name'] as String,
      ),
    );
    return result;
  }

  // ── Backup: Export / Import ────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'employees': _employees.map((e) => e.toMap()).toList(),
      'payments': _payments.map((p) => p.toMap()).toList(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    _employees.clear();
    _payments.clear();
    _empIdCounter = 0;
    _payIdCounter = 0;

    final employees = data['employees'] as List<dynamic>? ?? [];
    for (final empMap in employees) {
      final e = Employee.fromMap(Map<String, dynamic>.from(empMap as Map));
      _empIdCounter++;
      _employees.add(e.copyWith(id: e.id ?? _empIdCounter));
      if ((e.id ?? 0) > _empIdCounter) _empIdCounter = e.id!;
    }

    final payments = data['payments'] as List<dynamic>? ?? [];
    for (final payMap in payments) {
      final p = Payment.fromMap(Map<String, dynamic>.from(payMap as Map));
      _payIdCounter++;
      _payments.add(p.copyWith(id: p.id ?? _payIdCounter));
      if ((p.id ?? 0) > _payIdCounter) _payIdCounter = p.id!;
    }
  }
}
