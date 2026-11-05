import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_layout.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!context.read<AuthStore>().emailExists(_email.text)) {
      snack(context, 'Email tidak terdaftar.', error: true);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: _email.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Form(
        key: _form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Lupa kata sandi',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text(
              'Masukkan email akun Anda. Kode reset dikirim melalui email (simulasi).',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Masukkan email yang valid',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
              label: 'Kirim kode reset', loading: _loading, onPressed: _send),
        ]),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _reset() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthStore>().resetPassword(widget.email, _pass.text);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessView(
        title: 'Kata sandi diperbarui',
        message: 'Silakan masuk menggunakan kata sandi baru Anda.',
        primaryLabel: 'Ke halaman masuk',
        onPrimary: (c) => Navigator.of(c, rootNavigator: true)
            .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final minPass = context.read<SettingsStore>().minPasswordLength;
    return AuthLayout(
      showBack: true,
      child: Form(
        key: _form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Atur ulang kata sandi',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(
              'Kode dikirim ke ${widget.email} (simulasi). Gunakan kode 123456.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _code,
            label: 'Kode reset',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            validator: (v) =>
                v?.trim() == '123456' ? null : 'Kode tidak sesuai',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _pass,
            label: 'Kata sandi baru',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => (v == null || v.length < minPass)
                ? 'Kata sandi minimal $minPass karakter'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirm,
            label: 'Konfirmasi kata sandi baru',
            icon: Icons.lock_reset_outlined,
            isPassword: true,
            validator: (v) => v != _pass.text ? 'Kata sandi tidak sama' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Simpan kata sandi', onPressed: _reset),
        ]),
      ),
    );
  }
}
