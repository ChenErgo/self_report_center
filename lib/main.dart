import 'package:flutter/material.dart';

import 'app.dart';
import 'data/account_repository.dart';
import 'data/app_database.dart';
import 'data/report_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.openAndSeed();
  final reportRepository = ReportRepository(database);
  final accountRepository = AccountRepository(database);
  runApp(
    AdminApp(
      reportRepository: reportRepository,
      accountRepository: accountRepository,
    ),
  );
}
