import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/employee.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'employee_caller_id.db');
    return await openDatabase(
      path,
      version: 3, // v3: 컬럼 간소화 (v0.22)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department TEXT,
        name TEXT NOT NULL,
        rank TEXT,
        position TEXT,
        email TEXT,
        phone_number TEXT NOT NULL,
        office_phone TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX idx_phone ON employees (phone_number)');
    await db.execute('CREATE INDEX idx_office_phone ON employees (office_phone)');
    await db.execute('CREATE INDEX idx_name ON employees (name)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v3 업그레이드 시 기존 테이블 삭제 후 재생성
      await db.execute('DROP TABLE IF EXISTS employees');
      await _onCreate(db, newVersion);
    }
  }

  Future<int> insertEmployee(Employee employee) async {
    Database db = await database;
    return await db.insert('employees', employee.toMap());
  }

  Future<void> insertEmployeesBatch(List<Employee> employees) async {
    Database db = await database;
    Batch batch = db.batch();
    for (var emp in employees) {
      batch.insert('employees', emp.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Employee>> searchEmployees(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'name LIKE ? OR phone_number LIKE ? OR department LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<Employee?> getEmployeeByPhone(String phoneNumber) async {
    Database db = await database;
    // v3.2: 더욱 강력한 번호 정규화 (10... -> 010..., 8210... -> 010...)
    String cleaned = phoneNumber.replaceAll('-', '').replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '');
    if (cleaned.startsWith('+82')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('82')) cleaned = cleaned.substring(2);
    if (cleaned.startsWith('10') && cleaned.length == 10) cleaned = '0$cleaned';
    
    List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: "REPLACE(REPLACE(phone_number, '-', ''), ' ', '') = ? OR REPLACE(REPLACE(office_phone, '-', ''), ' ', '') = ? OR REPLACE(REPLACE(phone_number, '-', ''), ' ', '') = ? OR REPLACE(REPLACE(office_phone, '-', ''), ' ', '') = ?",
      whereArgs: [cleaned, cleaned, cleaned.startsWith('0') ? cleaned.substring(1) : cleaned, cleaned.startsWith('0') ? cleaned.substring(1) : cleaned],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    Database db = await database;
    return await db.query('employees');
  }

  Future<String> getDbPath() async {
    return join(await getDatabasesPath(), 'employee_caller_id.db');
  }

  Future<void> clearAll() async {
    Database db = await database;
    await db.delete('employees');
  }
}
