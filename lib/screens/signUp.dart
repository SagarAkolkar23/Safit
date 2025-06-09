import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:safit/Constant.dart';

/// Sign‑up screen that posts directly to the Node/Express
/// endpoint you shared (`/auth/register`).  Fields match the
/// *exact* JSON keys expected by the backend.
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final _dio = Dio(BaseOptions(
    baseUrl: baseUrlMain,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  // ───────────────────────── State ───────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _numCtrl     = TextEditingController(); // <- `number` in API
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _addrCtrl    = TextEditingController();
  String? _bloodGroup;
  final _bloodGroups = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];

  // Emergency 1
  final _ec1Name = TextEditingController();
  final _ec1Num  = TextEditingController();
  final _ec1Rel  = TextEditingController();
  // Emergency 2
  final _ec2Name = TextEditingController();
  final _ec2Num  = TextEditingController();
  final _ec2Rel  = TextEditingController();

  bool _hidePass = true, _hideConfirm = true, _loading = false;

  // ───────────────────────── UI ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.health_and_safety),
            SizedBox(width: 8),
            Text('Emergency Sign‑Up'),
          ],
        ),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _input(_nameCtrl, 'Full name', Icons.person),
              _gap(),
              _input(_emailCtrl, 'Email', Icons.email,
                  keyboard: TextInputType.emailAddress,),
              _gap(),
              _input(_numCtrl, 'Phone number', Icons.phone,
                  keyboard: TextInputType.phone),
              _gap(),
              _passwordField(_passCtrl, 'Password', false),
              _gap(),
              _passwordField(_confirmCtrl, 'Confirm password', true),
              _gap(),
              _bloodDropdown(),
              _gap(),
              _input(_addrCtrl, 'Address', Icons.home, maxLines: 3),
              const SizedBox(height: 28),
              Text('Emergency contacts', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              _contactBlock('Primary', _ec1Name, _ec1Num, _ec1Rel, required: true),
              _gap(height: 24),
              _contactBlock('Secondary (optional)', _ec2Name, _ec2Num, _ec2Rel, required: false),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _loading ? const SizedBox.shrink() : const Icon(Icons.login),
                label: Text(_loading ? 'Creating…' : 'SIGN UP'),
                onPressed: _loading ? null : _submit,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ──────────────────── Builders/helpers ─────────────────────
  Widget _gap({double height = 15}) => SizedBox(height: height);

  Widget _input(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (v) => v == null || v.trim().isEmpty ? 'Enter ${label.toLowerCase()}' : null,
    );
  }

  Widget _passwordField(TextEditingController c, String label, bool confirm) {
    return StatefulBuilder(builder: (context, setLocal) {
      final hide = confirm ? _hideConfirm : _hidePass;
      return TextFormField(
        controller: c,
        obscureText: hide,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setLocal(() {
              if (confirm) _hideConfirm = !_hideConfirm; else _hidePass = !_hidePass;
            }),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Enter ${label.toLowerCase()}';
          if (!confirm && v.length < 6) return 'Minimum 6 characters';
          if (confirm && v != _passCtrl.text) return 'Passwords do not match';
          return null;
        },
      );
    });
  }

  Widget _bloodDropdown() {
    return DropdownButtonFormField<String>(
      value: _bloodGroup,
      decoration: const InputDecoration(
        labelText: 'Blood group',
        prefixIcon: Icon(Icons.bloodtype),
        border: OutlineInputBorder(),
      ),
      items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _bloodGroup = v),
      validator: (v) => v == null ? 'Select blood group' : null,
    );
  }

  Widget _contactBlock(String label, TextEditingController name, TextEditingController num, TextEditingController rel, {required bool required}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      _gap(height: 12),
      _input(name, 'Name', Icons.person, validator: required ? null : (v) => null),
      _gap(height: 10),
      _input(num, 'Phone number', Icons.phone, keyboard: TextInputType.phone, validator: required ? null : (v) => null),
      _gap(height: 10),
      _input(rel, 'Relation', Icons.group, validator: required ? null : (v) => null),
    ]);
  }



  // ──────────────────── Submit to API ───────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final body = {
      'name'       : _nameCtrl.text.trim(),
      'email'      : _emailCtrl.text.trim(),
      'number'     : _numCtrl.text.trim(), // key name matches backend
      'password'   : _passCtrl.text.trim(),
      'bloodGroup' : _bloodGroup,
      'address'    : _addrCtrl.text.trim(),
      'emergencyContacts': [
        {
          'name'    : _ec1Name.text.trim(),
          'number'  : _ec1Num.text.trim(),
          'relation': _ec1Rel.text.trim(),
        },
        if (_ec2Num.text.trim().isNotEmpty)
          {
            'name'    : _ec2Name.text.trim(),
            'number'  : _ec2Num.text.trim(),
            'relation': _ec2Rel.text.trim(),
          }
      ]
    };

    try {
      final res = await _dio.post('/user/register', data: body);
      if (res.statusCode == 201) {

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful')));
        Navigator.pop(context);
      } else {
        final msg = res.data is Map && res.data['message'] is String
            ? res.data['message']
            : 'Unknown error';
        _showErr(msg);      }
    } on DioException catch (e) {
      final resData = e.response?.data;
      debugPrint('❌ Dio error response: $resData');

      // Safer message extraction
      String msg;
      if (resData is Map && resData['message'] is String) {
        msg = resData['message'];
      } else {
        msg = e.message ?? 'Network error';
      }

      _showErr(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────────── Dispose ────────────────────────────────
  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _numCtrl,
      _passCtrl,
      _confirmCtrl,
      _addrCtrl,
      _ec1Name,
      _ec1Num,
      _ec1Rel,
      _ec2Name,
      _ec2Num,
      _ec2Rel,
    ]) c.dispose();
    super.dispose();
  }
}