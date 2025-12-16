import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../data/account_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.accountRepository,
    required this.onLoggedIn,
  });

  final AccountRepository accountRepository;
  final void Function(String username) onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();

  String _captchaText = _generateCaptcha();
  bool _loading = false;
  String? _error;
  bool _rememberMe = true;

  static String _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    _captchaController.text = _captchaText;
    _loadRemembered();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _refreshCaptcha() {
    setState(() {
      _captchaText = _generateCaptcha();
      _captchaController.text = _captchaText;
    });
  }

  Future<void> _handleLogin() async {
    if (_userController.text.trim().isEmpty) {
      setState(() => _error = '请输入账号');
      return;
    }
    if (_passController.text.isEmpty) {
      setState(() => _error = '请输入密码');
      return;
    }
    if (_captchaController.text.trim().isEmpty) {
      setState(() => _error = '请输入验证码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final username = _userController.text.trim();
    final password = _passController.text;
    final inputCaptcha = _captchaController.text.trim().toUpperCase();
    if (inputCaptcha != _captchaText.toUpperCase()) {
      setState(() {
        _loading = false;
        _error = '验证码不正确';
      });
      _refreshCaptcha();
      return;
    }
    final account = await widget.accountRepository.findByUsername(username);
    if (account == null || account.status != 'active' || !account.verifyPassword(password)) {
      setState(() {
        _loading = false;
        _error = '账号或密码错误，或账号已禁用';
      });
      _refreshCaptcha();
      return;
    }
    setState(() => _loading = false);
    await _persistRemembered();
    widget.onLoggedIn(account.username);
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F4F1), Color(0xFFD1E6DF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 10,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(color: theme.brandColor1),
                            child: const Icon(Icons.desktop_mac, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('管理后台登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('桌面端，请输入账号、密码与验证码', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      TDInput(
                        leftLabel: '账号',
                        controller: _userController,
                        hintText: '请输入账号',
                        backgroundColor: Colors.white,
                        needClear: true,
                      ),
                      const SizedBox(height: 16),
                      TDInput(
                        leftLabel: '密码',
                        controller: _passController,
                        hintText: '请输入密码',
                        obscureText: true,
                        backgroundColor: Colors.white,
                        needClear: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TDInput(
                                leftLabel: '验证码',
                                controller: _captchaController,
                                hintText: '请输入验证码',
                                backgroundColor: Colors.white,
                                needClear: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _refreshCaptcha,
                              child: CaptchaBox(text: _captchaText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      TDCheckbox(
                        id: 'remember',
                        title: '记住账号和密码（仅本机存储）',
                        checked: _rememberMe,
                        onCheckBoxChanged: (checked) {
                          setState(() {
                            _rememberMe = checked;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052D9),
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('登录'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadRemembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_flag') ?? true;
      final user = prefs.getString('remember_user');
      final pass = prefs.getString('remember_pass');
      if (!mounted) return;
      setState(() {
        _rememberMe = remember;
        if (user != null) _userController.text = user;
        if (pass != null) _passController.text = pass;
      });
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> _persistRemembered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remember_user', _userController.text.trim());
        await prefs.setString('remember_pass', _passController.text);
        await prefs.setBool('remember_flag', true);
      } else {
        await prefs.remove('remember_user');
        await prefs.remove('remember_pass');
        await prefs.setBool('remember_flag', false);
      }
    } catch (_) {
      // ignore persistence errors
    }
  }
}

class CaptchaBox extends StatelessWidget {
  const CaptchaBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(120, 48),
        painter: _CaptchaPainter(text),
      ),
    );
  }
}

class _CaptchaPainter extends CustomPainter {
  _CaptchaPainter(this.text);

  final String text;
  final Random _rand = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    for (var i = 0; i < 6; i++) {
      final paint = Paint()
        ..color = Colors.teal.withOpacity(0.5)
        ..strokeWidth = 1.2;
      final p1 = Offset(_rand.nextDouble() * size.width, _rand.nextDouble() * size.height);
      final p2 = Offset(_rand.nextDouble() * size.width, _rand.nextDouble() * size.height);
      canvas.drawLine(p1, p2, paint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.teal.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final offset = Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CaptchaPainter oldDelegate) => oldDelegate.text != text;
}
