import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/account_model.dart';
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
  final _formKey = GlobalKey<FormState>();

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
    _loadRemembered();
  }

  void _refreshCaptcha() {
    setState(() {
      _captchaText = _generateCaptcha();
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 4,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                          ),
                          child: const Icon(Icons.security, color: Colors.teal),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('管理后台登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('请输入账号、密码与验证码'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _userController,
                    decoration: const InputDecoration(
                      labelText: '账号',
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      prefixIcon: Icon(Icons.person),
                    ),
                      validator: (v) => (v == null || v.isEmpty) ? '请输入账号' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passController,
                      obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      prefixIcon: Icon(Icons.lock),
                    ),
                      validator: (v) => (v == null || v.isEmpty) ? '请输入密码' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _captchaController,
                            decoration: const InputDecoration(
                              labelText: '验证码',
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                              prefixIcon: Icon(Icons.verified),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? '请输入验证码' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _refreshCaptcha,
                          child: CaptchaBox(text: _captchaText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _handleLogin,
                        icon: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('登录'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _rememberMe,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _rememberMe = v);
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('记住账号和密码（仅本机存储）'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _captchaController.dispose();
    super.dispose();
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
      // Ignore persistence errors on desktop; fall back to manual input.
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
      // Ignore persistence errors; do not block login.
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

    // Noise lines
    for (var i = 0; i < 6; i++) {
      final paint = Paint()
        ..color = Colors.teal.withOpacity(0.5)
        ..strokeWidth = 1.2;
      final p1 = Offset(_rand.nextDouble() * size.width, _rand.nextDouble() * size.height);
      final p2 = Offset(_rand.nextDouble() * size.width, _rand.nextDouble() * size.height);
      canvas.drawLine(p1, p2, paint);
    }

    // Text
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
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CaptchaPainter oldDelegate) {
    return oldDelegate.text != text;
  }
}
