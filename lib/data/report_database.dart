import 'dart:io';

import 'package:faker/faker.dart' as fk;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'report_model.dart';

class ReportDatabase {
  ReportDatabase(this.db);

  final Database db;

  static Future<ReportDatabase> openAndSeed() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final dbPath = await factory.getDatabasesPath();
    await Directory(dbPath).create(recursive: true);
    final path = p.join(dbPath, 'self_report_center.db');
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
        },
      ),
    );

    final repo = ReportDatabase(database);
    await repo._seedIfEmpty();
    return repo;
  }

  Future<void> _seedIfEmpty() async {
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM reports');
    final count = (result.first['cnt'] as int?) ?? 0;
    if (count > 0) return;
    final faker = fk.Faker();
    for (var i = 0; i < 30; i++) {
      await insert(ReportRecord.fake(faker));
    }
  }

  Future<List<ReportRecord>> fetchAll({String query = '', String? category}) async {
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

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM reports WHERE id IN ($placeholders)', ids);
  }

  Future<int> insert(ReportRecord record) {
    return db.insert('reports', record.toMap());
  }

  Future<void> update(ReportRecord record) async {
    if (record.id == null) return;
    await db.update(
      'reports',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }
}
