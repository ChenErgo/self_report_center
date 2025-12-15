import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/menu_keys.dart';
import 'account_model.dart';
import 'report_model.dart';
import 'role_model.dart';

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
        version: 5,
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
          if (oldVersion < 4) {
            await _createRolesTables(db);
            await _seedRoles(db);
          }
          if (oldVersion < 5) {
            await _addRoleStatusColumn(db);
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
    await _createRolesTables(db);
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

  static Future<void> _addRoleStatusColumn(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(roles)");
    final hasStatus = columns.any((row) => row['name'] == 'status');
    if (!hasStatus) {
      await db.execute("ALTER TABLE roles ADD COLUMN status TEXT DEFAULT 'active';");
      await db.update('roles', {'status': 'active'});
    }
  }

  static Future<void> _createRolesTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        description TEXT,
        status TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_roles (
        accountId INTEGER,
        roleId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        roleId INTEGER,
        permissionKey TEXT
      )
    ''');
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
    await _createRolesTables(db);
    await _addRoleStatusColumn(db);
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
    // ensure super_admin role assignment
    final roles = await fetchRolesWithPermissions();
    final superRole = roles.firstWhere((r) => r.name == 'super_admin', orElse: () => RoleRecord(id: null, name: 'super_admin', description: '超级管理员', permissions: kMenuPermissions.map((e) => e.key).toList()));
    int roleId = superRole.id ?? await insertRole(superRole);
    await db.insert('account_roles', {'accountId': 1, 'roleId': roleId});
  }

  static Future<void> _seedRoles(Database db) async {
    final existing = await db.rawQuery('SELECT COUNT(*) as cnt FROM roles');
    final count = (existing.first['cnt'] as int?) ?? 0;
    if (count > 0) return;
    final allPerms = kMenuPermissions.map((e) => e.key).toList();
    final roleId = await db.insert('roles', {
      'name': 'super_admin',
      'description': '超级管理员',
      'status': 'active',
    });
    for (final perm in allPerms) {
      await db.insert('role_permissions', {'roleId': roleId, 'permissionKey': perm});
    }
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
    await db.rawDelete('DELETE FROM account_roles WHERE accountId IN ($placeholders)', ids);
    await db.rawDelete('DELETE FROM accounts WHERE id IN ($placeholders)', ids);
  }

  // Roles
  Future<List<RoleRecord>> fetchRolesWithPermissions({String query = '', String? status}) async {
    final conditions = <String>[];
    final args = <Object?>[];
    if (query.isNotEmpty) {
      conditions.add('(name LIKE ? OR description LIKE ?)');
      args..add('%$query%')..add('%$query%');
    }
    if (status != null && status.isNotEmpty) {
      conditions.add('status = ?');
      args.add(status);
    }
    final rolesRaw = await db.query(
      'roles',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: 'id ASC',
    );
    final permsRaw = await db.query('role_permissions');
    return rolesRaw.map((r) {
      final id = r['id'] as int;
      final perms = permsRaw.where((p) => p['roleId'] == id).map((p) => p['permissionKey'] as String).toList();
      return RoleRecord(
        id: id,
        name: (r['name'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        status: (r['status'] ?? 'active') as String,
        permissions: perms,
      );
    }).toList();
  }

  Future<int> insertRole(RoleRecord role) async {
    final roleId = await db.insert('roles', {
      'name': role.name,
      'description': role.description,
      'status': role.status,
    });
    await _replaceRolePermissions(roleId, role.permissions);
    return roleId;
  }

  Future<void> updateRole(RoleRecord role) async {
    if (role.id == null) return;
    await db.update(
      'roles',
      {'name': role.name, 'description': role.description, 'status': role.status},
      where: 'id = ?',
      whereArgs: [role.id],
    );
    await _replaceRolePermissions(role.id!, role.permissions);
  }

  Future<void> deleteRole(int roleId) async {
    await db.delete('account_roles', where: 'roleId = ?', whereArgs: [roleId]);
    await db.delete('role_permissions', where: 'roleId = ?', whereArgs: [roleId]);
    await db.delete('roles', where: 'id = ?', whereArgs: [roleId]);
  }

  Future<void> _replaceRolePermissions(int roleId, List<String> perms) async {
    await db.delete('role_permissions', where: 'roleId = ?', whereArgs: [roleId]);
    for (final perm in perms) {
      await db.insert('role_permissions', {'roleId': roleId, 'permissionKey': perm});
    }
  }

  Future<AccountRecord?> getAccountDetail(String username) async {
    final rows = await db.query('accounts', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    final account = AccountRecord.fromMap(rows.first);
    final roles = await _getRolesForAccount(account.id);
    return account.copyWith(roles: roles);
  }

  Future<List<AccountRecord>> getAllAccountsDetailed({String query = ''}) async {
    final accounts = await getAllAccounts(query: query);
    final result = <AccountRecord>[];
    for (final acct in accounts) {
      final roles = await _getRolesForAccount(acct.id);
      result.add(acct.copyWith(roles: roles));
    }
    return result;
  }

  Future<List<RoleRecord>> _getRolesForAccount(int? accountId) async {
    if (accountId == null) return [];
    final raw = await db.rawQuery('''
      SELECT roles.id, roles.name, roles.description, roles.status
      FROM account_roles
      JOIN roles ON roles.id = account_roles.roleId
      WHERE account_roles.accountId = ?
    ''', [accountId]);
    final permsRaw = await db.query('role_permissions');
    return raw.map((r) {
      final id = r['id'] as int;
      final perms = permsRaw.where((p) => p['roleId'] == id).map((p) => p['permissionKey'] as String).toList();
      return RoleRecord(
        id: id,
        name: (r['name'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        status: (r['status'] ?? 'active') as String,
        permissions: perms,
      );
    }).toList();
  }

  Future<void> replaceAccountRoles(int accountId, List<int> roleIds) async {
    await db.delete('account_roles', where: 'accountId = ?', whereArgs: [accountId]);
    for (final id in roleIds) {
      await db.insert('account_roles', {'accountId': accountId, 'roleId': id});
    }
  }
}
