import 'app_database.dart';
import 'report_model.dart';

class ReportRepository {
  ReportRepository(this.db);

  final AppDatabase db;

  Future<List<ReportRecord>> fetch({
    String query = '',
    String? category,
  }) {
    return db.fetchReports(query: query, category: category);
  }

  Future<void> deleteMany(Set<int> ids) async {
    await db.deleteReportsByIds(ids.toList());
  }

  Future<void> deleteOne(int id) async {
    await db.deleteReportsByIds([id]);
  }

  Future<int> create(ReportRecord record) {
    return db.insertReport(record);
  }

  Future<void> update(ReportRecord record) {
    return db.updateReport(record);
  }
}
