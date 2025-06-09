import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:safit/Constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Dio dio = Dio(BaseOptions(
  baseUrl: baseUrlMain,
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 20),
  headers: {'Content-Type': 'application/json'},
));

class EmergencyLoginPage extends StatefulWidget {
  const EmergencyLoginPage({super.key});

  @override
  State<EmergencyLoginPage> createState() => _EmergencyLoginPageState();
}

class _EmergencyLoginPageState extends State<EmergencyLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _hidePass = true, _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final response = await dio.post(
        '/user/login',
        data: {
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        },
      );

      debugPrint('🔵 RAW RESPONSE: ${response.data}');

      if (response.statusCode == 200 && response.data?['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.data['token']);
        await prefs.setString('user', jsonEncode(response.data['newUser'])); // <== FIXED HERE

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErr(response.data['message'] ?? 'Unknown error');
      }
    } on DioException catch (e) {
      debugPrint('❌ DIO ERROR: ${e.response?.data ?? e.message}');
      final msg = e.response?.data is Map && e.response!.data['message'] is String
          ? e.response!.data['message']
          : e.message ?? 'Network error';
      _showErr(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErr(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final red = Colors.red[900]!;
    return Scaffold(
      backgroundColor: red,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 100, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Emergency Login',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),

                  // ─── Email ─────────────────────────────────────
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.red[700],
                      prefixIcon:
                      const Icon(Icons.email, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Enter your email'
                        : !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
                        ? 'Invalid email'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ─── Password ────────────────────────────────
                  StatefulBuilder(builder: (context, setLocal) {
                    return TextFormField(
                      controller: _passCtrl,
                      obscureText: _hidePass,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.red[700],
                        prefixIcon:
                        const Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _hidePass ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70),
                          onPressed: () => setLocal(() {
                            _hidePass = !_hidePass;
                          }),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter password'
                          : v.length < 6
                          ? 'Min 6 characters'
                          : null,
                    );
                  }),
                  const SizedBox(height: 32),

                  // ─── Login Button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                          : const Icon(Icons.login, size: 26),
                      label: Text(
                        _loading ? 'Logging in…' : 'LOGIN',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Go to Sign-Up ───────────────────────────
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () =>
                        Navigator.pushReplacementNamed(context, '/signup'),
                    child: const Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}