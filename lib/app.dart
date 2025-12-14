import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/account_repository.dart';
import 'data/report_repository.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({
    super.key,
    required this.reportRepository,
    required this.accountRepository,
  });

  final ReportRepository reportRepository;
  final AccountRepository accountRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Desktop Admin',
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      home: _RootShell(
        reportRepository: reportRepository,
        accountRepository: accountRepository,
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell({
    required this.reportRepository,
    required this.accountRepository,
  });

  final ReportRepository reportRepository;
  final AccountRepository accountRepository;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  String? _loggedInUser;

  void _handleLogin(String username) {
    setState(() {
      _loggedInUser = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInUser == null) {
      return LoginPage(
        accountRepository: widget.accountRepository,
        onLoggedIn: _handleLogin,
      );
    }
    return DashboardPage(
      reportRepository: widget.reportRepository,
      accountRepository: widget.accountRepository,
      currentUsername: _loggedInUser!,
      onLogout: () => setState(() => _loggedInUser = null),
    );
  }
}
