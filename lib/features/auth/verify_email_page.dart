import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/stores/auth_store.dart';
import 'package:sipintar/features/auth/auth_layout.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Verifikasi email SIMULASI. Kode demo: 123456.
class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _code = TextEditingController();
  Timer? _t;
  int _left = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _left = 30;
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left > 0 ? _left-- : t.cancel());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim() != '123456') {
      snack(context, 'Kode tidak sesuai. Gunakan kode demo 123456.', error: true);
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.read<AuthStore>().verifyEmail(widget.email);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessView(
        title: 'Email terverifikasi',
        message: 'Akun Anda sudah aktif. Silakan masuk menggunakan email dan kata sandi.',
        primaryLabel: 'Ke halaman masuk',
        onPrimary: (c) => Navigator.of(c, rootNavigator: true).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Verifikasi email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 4),
        Text('Kode 6 digit dikirim ke ${widget.email} (simulasi). Masukkan kode 123456.', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _code,
          label: 'Kode verifikasi',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Verifikasi', loading: _loading, onPressed: _verify),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _left > 0
              ? null
              : () {
                  _start();
                  snack(context, 'Kode verifikasi dikirim ulang (simulasi).');
                },
          child: Text(_left > 0 ? 'Kirim ulang kode dalam ${_left}s' : 'Kirim ulang kode'),
        ),
      ]),
    );
  }
}
