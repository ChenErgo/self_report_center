import 'report_database.dart';
import 'report_model.dart';

class ReportRepository {
  ReportRepository(this.database);

  final ReportDatabase database;

  Future<List<ReportRecord>> fetch({
    String query = '',
    String? category,
  }) {
    return database.fetchAll(query: query, category: category);
  }

  Future<void> deleteMany(Set<int> ids) async {
    await database.deleteByIds(ids.toList());
  }

  Future<void> deleteOne(int id) async {
    await database.deleteByIds([id]);
  }

  Future<int> create(ReportRecord record) {
    return database.insert(record);
  }

  Future<void> update(ReportRecord record) {
    return database.update(record);
  }
}
