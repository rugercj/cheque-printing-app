import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Stream Controllers
  final _employeeStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _supplierStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _paymentTypeStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _checkStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // ==========================================
  // FIXED STREAM GETTERS (Instant Real-time Sync)
  // ==========================================
  Stream<List<Map<String, dynamic>>> get employeeStream {
    scheduleMicrotask(() => refreshEmployeesStream());
    return _employeeStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> get supplierStream {
    scheduleMicrotask(() => refreshSuppliersStream());
    return _supplierStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> get paymentTypeStream {
    scheduleMicrotask(() => refreshPaymentTypesStream());
    return _paymentTypeStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> get checkStream {
    scheduleMicrotask(() => refreshChecksStream());
    return _checkStreamController.stream;
  }

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String path = join(appDocDir.path, filePath);

    // FIX: Incremented database version code to 5 to handle column structure upgrade modifications
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create Employees Table
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        email TEXT NOT NULL,
        number TEXT NOT NULL,
        gender TEXT NOT NULL,
        remarks TEXT
      )
    ''');

    // Create Suppliers Table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        telephoneno TEXT,
        remarks TEXT
      )
    ''');

    // Create Payment Types Table
    await db.execute('''
      CREATE TABLE payment_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL UNIQUE
      )
    ''');

    // FIX: Updated base schema design with new parameters for entirely clean app builds
    await db.execute('''
      CREATE TABLE checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_date TEXT NOT NULL,
        payee_name TEXT NOT NULL,
        amount REAL NOT NULL,
        is_cleared INTEGER DEFAULT 0,
        payment_type TEXT,
        check_no TEXT,
        particular TEXT,
        cv_no TEXT,
        bank_name TEXT,
        is_ac_payee INTEGER DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE suppliers ADD COLUMN telephoneno TEXT;');
      try {
        await db.execute('UPDATE suppliers SET telephoneno = number;');
      } catch (_) {}
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE payment_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type_name TEXT NOT NULL UNIQUE
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE checks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          check_date TEXT NOT NULL,
          payee_name TEXT NOT NULL,
          amount REAL NOT NULL,
          is_cleared INTEGER DEFAULT 0,
          payment_type TEXT,
          check_no TEXT
        )
      ''');
    }

    // FIX: Added safe continuous incremental structure path if updating existing software builds
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE checks ADD COLUMN particular TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE checks ADD COLUMN cv_no TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE checks ADD COLUMN bank_name TEXT;');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE checks ADD COLUMN is_ac_payee INTEGER DEFAULT 0;',
        );
      } catch (_) {}
    }
  }

  // ==========================================
  // EMPLOYEE METHODS
  // ==========================================

  Future<void> refreshEmployeesStream() async {
    final data = await queryAllEmployees();
    _employeeStreamController.add(data);
  }

  Future<int> insertEmployee(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('employees', row);
    await refreshEmployeesStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> queryAllEmployees() async {
    final db = await database;
    return await db.query('employees');
  }

  Future<int> updateEmployee(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'];
    final result = await db.update(
      'employees',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshEmployeesStream();
    return result;
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    final result = await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshEmployeesStream();
    return result;
  }

  // ==========================================
  // SUPPLIER METHODS
  // ==========================================

  Future<void> refreshSuppliersStream() async {
    final data = await queryAllSuppliers();
    _supplierStreamController.add(data);
  }

  Future<int> insertSupplier(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('suppliers', row);
    await refreshSuppliersStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> queryAllSuppliers() async {
    final db = await database;
    return await db.query('suppliers');
  }

  Future<int> updateSupplier(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'];
    final result = await db.update(
      'suppliers',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshSuppliersStream();
    return result;
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    final result = await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshSuppliersStream();
    return result;
  }

  // ==========================================
  // PAYMENT TYPE METHODS
  // ==========================================

  Future<void> refreshPaymentTypesStream() async {
    final data = await queryAllPaymentTypes();
    _paymentTypeStreamController.add(data);
  }

  Future<int> insertPaymentType(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('payment_types', row);
    await refreshPaymentTypesStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> queryAllPaymentTypes() async {
    final db = await database;
    return await db.query('payment_types');
  }

  Future<int> updatePaymentType(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'];
    final result = await db.update(
      'payment_types',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshPaymentTypesStream();
    return result;
  }

  Future<int> deletePaymentType(int id) async {
    final db = await database;
    final result = await db.delete(
      'payment_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshPaymentTypesStream();
    return result;
  }

  // ==========================================
  // CHECK PRINTING METHODS
  // ==========================================

  Future<void> refreshChecksStream() async {
    final data = await queryAllChecks();
    _checkStreamController.add(data);
  }

  Future<int> insertCheck(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('checks', row);
    await refreshChecksStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> queryAllChecks() async {
    final db = await database;
    return await db.query('checks');
  }

  Future<int> updateCheck(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'];
    final result = await db.update(
      'checks',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshChecksStream();
    return result;
  }

  Future<int> deleteCheck(int id) async {
    final db = await database;
    final result = await db.delete('checks', where: 'id = ?', whereArgs: [id]);
    await refreshChecksStream();
    return result;
  }
}
