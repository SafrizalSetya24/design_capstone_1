import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_layout.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final err = context.read<AuthStore>().login(_email.text.trim(), _pass.text);
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    const demo = ['sw1', 'gr1', 'sp1', 'ad1'];
    return AuthLayout(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Masuk ke SIPINTAR', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Gunakan akun sekolah Anda.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Format email belum benar';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _pass,
            label: 'Kata sandi',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.forgot),
              child: const Text('Lupa kata sandi?'),
            ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
              ]),
            ),
          PrimaryButton(label: 'Masuk', loading: _loading, onPressed: _submit),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Belum punya akun?', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.accountType), child: const Text('Daftar')),
          ]),
          const SizedBox(height: AppSpacing.md),
          const Text('Akun demo (kata sandi: sipintar123)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final id in demo)
              ActionChip(
                avatar: const Icon(Icons.person_outline, size: 16),
                label: Text(DummyData.user(id).role.label),
                onPressed: () => setState(() {
                  _email.text = DummyData.user(id).email;
                  _pass.text = DummyData.password;
                  _error = null;
                }),
              ),
          ]),
        ]),
      ),
    );
  }
}
