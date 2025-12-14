import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'account_model.dart';
import 'report_model.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static Future<AppDatabase> openAndSeed() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final dbPath = await factory.getDatabasesPath();
    await Directory(dbPath).create(recursive: true);
    final path = p.join(dbPath, 'self_report_center.db');
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createAccountsTable(db);
          }
          if (oldVersion < 3) {
            await _addAvatarColumn(db);
          }
        },
        onOpen: (db) async {
          await _ensureTables(db);
        },
      ),
    );

    final appDb = AppDatabase(database);
    await appDb._seedReportsIfEmpty();
    await appDb._seedAccountsIfEmpty();
    return appDb;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        owner TEXT,
        department TEXT,
        status TEXT,
        priority TEXT,
        category TEXT,
        subcategory TEXT,
        region TEXT,
        platform TEXT,
        version TEXT,
        severity TEXT,
        deviceId TEXT,
        os TEXT,
        city TEXT,
        country TEXT,
        contactEmail TEXT,
        contactPhone TEXT,
        tags TEXT,
        updatedAt TEXT
      )
    ''');
    await _createAccountsTable(db);
  }

  static Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        passwordHash TEXT,
        role TEXT,
        status TEXT,
        avatarPath TEXT,
        createdAt TEXT
      )
    ''');
  }

  static Future<void> _addAvatarColumn(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(accounts)");
    final hasAvatar = columns.any((row) => row['name'] == 'avatarPath');
    if (!hasAvatar) {
      await db.execute("ALTER TABLE accounts ADD COLUMN avatarPath TEXT;");
    }
  }

  static Future<void> _ensureTables(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'",
    );
    if (result.isEmpty) {
      await _createAccountsTable(db);
    } else {
      await _addAvatarColumn(db);
    }
  }

  Future<void> _seedReportsIfEmpty() async {
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM reports');
    final count = (result.first['cnt'] as int?) ?? 0;
    if (count > 0) return;
    final faker = fk.Faker();
    for (var i = 0; i < 30; i++) {
      await insertReport(ReportRecord.fake(faker));
    }
  }

  Future<void> _seedAccountsIfEmpty() async {
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM accounts');
    final count = (result.first['cnt'] as int?) ?? 0;
    if (count > 0) return;
    final now = DateTime.now().toIso8601String();
    // 默认超级管理员：账号 superchenergou / 密码 superchenergou （后续请修改或删除）
    await db.insert('accounts', {
      'username': 'superchenergou',
      'passwordHash': AccountRecord.hashPassword('superchenergou'),
      'role': 'super_admin',
      'status': 'active',
      'avatarPath': null,
      'createdAt': now,
    });
  }

  // Reports
  Future<List<ReportRecord>> fetchReports({String query = '', String? category}) async {
    final buffer = StringBuffer();
    final args = <Object?>[];
    if (query.isNotEmpty) {
      buffer.write(
        'WHERE (title LIKE ? OR owner LIKE ? OR category LIKE ? OR tags LIKE ?)',
      );
      args.addAll(List.generate(4, (_) => '%$query%'));
    }
    if (category != null && category.isNotEmpty) {
      if (buffer.isEmpty) {
        buffer.write('WHERE category = ?');
      } else {
        buffer.write(' AND category = ?');
      }
      args.add(category);
    }
    final rows = await db.rawQuery(
      'SELECT * FROM reports ${buffer.toString()} ORDER BY updatedAt DESC',
      args,
    );
    return rows.map((e) => ReportRecord.fromMap(e)).toList();
  }

  Future<void> deleteReportsByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM reports WHERE id IN ($placeholders)', ids);
  }

  Future<int> insertReport(ReportRecord record) {
    return db.insert('reports', record.toMap());
  }

  Future<void> updateReport(ReportRecord record) async {
    if (record.id == null) return;
    await db.update(
      'reports',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // Accounts
  Future<AccountRecord?> getAccountByUsername(String username) async {
    final rows = await db.query('accounts', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    return AccountRecord.fromMap(rows.first);
  }

  Future<List<AccountRecord>> getAllAccounts({String query = ''}) async {
    if (query.isEmpty) {
      final rows = await db.query('accounts', orderBy: 'createdAt DESC');
      return rows.map(AccountRecord.fromMap).toList();
    }
    final like = '%$query%';
    final rows = await db.query(
      'accounts',
      where: 'username LIKE ? OR role LIKE ? OR status LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'createdAt DESC',
    );
    return rows.map(AccountRecord.fromMap).toList();
  }

  Future<int> insertAccount(AccountRecord account) {
    return db.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(AccountRecord account) async {
    if (account.id == null) return;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccounts(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM accounts WHERE id IN ($placeholders)', ids);
  }
}
