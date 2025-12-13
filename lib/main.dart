import 'package:flutter/material.dart';

import 'app.dart';
import 'data/report_database.dart';
import 'data/report_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await ReportDatabase.openAndSeed();
  final repository = ReportRepository(database);
  runApp(AdminApp(repository: repository));
}
