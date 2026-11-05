import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_layout.dart';
import 'package:sipintar/features/auth/verify_email_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Registrasi Siswa (NIS + Kelas) atau Guru (NIK + Jabatan/mapel). Dua form berbeda, tidak dicampur.
class RegisterPage extends StatefulWidget {
  final UserRole role;
  const RegisterPage({super.key, required this.role});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _identity = TextEditingController();
  final _extra = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String? _kelas;
  bool _loading = false;

  static const kelasList = RegisterPageKelas.list;
  bool get _siswa => widget.role == UserRole.siswa;

  @override
  void dispose() {
    for (final c in [_name, _email, _identity, _extra, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final err = context.read<AuthStore>().register(
          role: widget.role,
          name: _name.text,
          email: _email.text,
          identity: _identity.text.trim(),
          extra: _siswa ? (_kelas ?? '') : _extra.text,
          password: _pass.text,
        );
    setState(() => _loading = false);
    if (err != null) {
      snack(context, err, error: true);
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => VerifyEmailPage(email: _email.text.trim())));
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
          Text('Registrasi ${widget.role.label}',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(
              _siswa
                  ? 'Isi data diri dengan NIS dan kelas Anda.'
                  : 'Isi data diri dengan NIK dan jabatan atau mata pelajaran Anda.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _name,
            label: 'Nama lengkap',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Nama lengkap minimal 3 karakter'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
          if (_siswa) ...[
            AppTextField(
              controller: _identity,
              label: 'NIS',
              hint: 'Contoh: 2024001234',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'NIS wajib diisi';
                if (t.length < 8) return 'NIS terdiri dari 8-10 digit';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown.strings(
              label: 'Kelas',
              icon: Icons.school_outlined,
              value: _kelas,
              options: kelasList,
              onChanged: (v) => setState(() => _kelas = v),
              validator: (v) => v == null ? 'Pilih kelas' : null,
            ),
          ] else ...[
            AppTextField(
              controller: _identity,
              label: 'NIK',
              hint: '16 digit sesuai KTP',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 16,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'NIK wajib diisi';
                if (t.length != 16) return 'NIK terdiri dari 16 digit';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _extra,
              label: 'Jabatan / mata pelajaran',
              hint: 'Contoh: Informatika',
              icon: Icons.menu_book_outlined,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Jabatan atau mata pelajaran wajib diisi'
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _pass,
            label: 'Kata sandi',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => (v == null || v.length < minPass)
                ? 'Kata sandi minimal $minPass karakter'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirm,
            label: 'Konfirmasi kata sandi',
            icon: Icons.lock_reset_outlined,
            isPassword: true,
            validator: (v) => v != _pass.text ? 'Kata sandi tidak sama' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Daftar', loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}

class RegisterPageKelas {
  RegisterPageKelas._();
  static const list = [
    'X RPL 1',
    'X RPL 2',
    'X TKJ 1',
    'X TKJ 2',
    'XI RPL 1',
    'XI RPL 2',
    'XI TKJ 1',
    'XI AKL 1',
    'XII MM 1',
    'XII RPL 1'
  ];
}
