import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/auth_actions.dart';
import 'package:sipintar/features/auth/register_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Profil untuk semua role. Bagian "Data Siswa"/"Data Guru" dibentuk dari model masing-masing.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    Widget menu(IconData i, String t, VoidCallback f, {Color? color}) =>
        ListTile(
          leading: Icon(i, color: color),
          title: Text(t, style: TextStyle(color: color)),
          trailing: const Icon(Icons.chevron_right),
          onTap: f,
        );
    final title = switch (user.role) {
      UserRole.admin => 'Profil Admin',
      UserRole.sapras => 'Profil dan Pengaturan',
      _ => 'Profil',
    };

    return AppPage(
      title: title,
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left: AppCard(
            child: Column(children: [
              CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.navy,
                  child: Text(user.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800))),
              const SizedBox(height: AppSpacing.md),
              Text(user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Center(child: IdentityBadge(user: user)),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => snack(context,
                    'Unggah foto profil disimulasikan pada tahap frontend ini.'),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ubah foto'),
              ),
            ]),
          ),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionHeader(user.profileSectionTitle),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                for (final f in user.profileFields)
                  ListTile(
                    leading: Icon(f.icon, color: AppColors.blue),
                    title: Text(f.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: Text(f.value,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Pengaturan akun'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                menu(Icons.edit_outlined, 'Edit profil',
                    () => push(context, const EditProfilePage())),
                menu(
                    Icons.face_retouching_natural_rounded,
                    'Data biometrik wajah',
                    () => Navigator.of(context)
                        .pushNamed(AppRoutes.faceRegistration)),
                menu(Icons.lock_outline, 'Ubah kata sandi',
                    () => push(context, const ChangePasswordPage())),
                menu(Icons.notifications_none, 'Pengaturan notifikasi',
                    () => push(context, const NotificationSettingsPage())),
                menu(Icons.info_outline, 'Informasi aplikasi',
                    () => push(context, const AppInfoPage())),
                menu(Icons.logout, 'Keluar', () => confirmLogout(context),
                    color: AppColors.danger),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _extra, _identity;
  String? _kelas;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthStore>().currentUser!;
    _name = TextEditingController(text: u.name);
    _email = TextEditingController(text: u.email);
    _extra = TextEditingController(
        text: u.role == UserRole.guru ? (u.extraValue ?? '') : '');
    _identity = TextEditingController(text: u.identityValue);
    _kelas = u.role == UserRole.siswa ? u.extraValue : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _extra.dispose();
    _identity.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthStore>();
    final u = auth.currentUser!;
    final extra = u.role == UserRole.siswa
        ? _kelas
        : (u.role == UserRole.guru ? _extra.text : null);
    final err =
        auth.updateProfile(name: _name.text, email: _email.text, extra: extra);
    if (err != null) {
      snack(context, err, error: true);
      return;
    }
    snack(context, 'Profil berhasil diperbarui.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthStore>().currentUser!;
    final kelas = (_kelas == null || RegisterPageKelas.list.contains(_kelas))
        ? RegisterPageKelas.list
        : [...RegisterPageKelas.list, _kelas!];
    return FormScaffold(
      title: 'Edit Profil',
      formKey: _form,
      submitLabel: 'Simpan perubahan',
      onSubmit: _save,
      children: [
        FormRow(children: [
          AppTextField(
              controller: _name,
              label: 'Nama lengkap',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Nama minimal 3 karakter'
                  : null),
          AppTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.mail_outline,
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Masukkan email yang valid',
          ),
        ]),
        FormRow(children: [
          AppTextField(
              controller: _identity,
              label: u.identityLabel,
              icon: Icons.badge_outlined,
              readOnly: true,
              hint: 'Tidak dapat diubah'),
          if (u.role == UserRole.siswa)
            AppDropdown.strings(
                label: 'Kelas',
                icon: Icons.school_outlined,
                value: _kelas,
                options: kelas,
                onChanged: (v) => setState(() => _kelas = v))
          else if (u.role == UserRole.guru)
            AppTextField(
                controller: _extra,
                label: 'Jabatan / mata pelajaran',
                icon: Icons.menu_book_outlined,
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Wajib diisi' : null)
          else
            AppTextField(
                controller: TextEditingController(text: u.role.label),
                label: 'Role',
                icon: Icons.verified_user_outlined,
                readOnly: true),
        ]),
      ],
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final err = context.read<AuthStore>().changePassword(_old.text, _new.text);
    if (err != null) {
      snack(context, err, error: true);
      return;
    }
    snack(context, 'Kata sandi berhasil diubah.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final minPass = context.read<SettingsStore>().minPasswordLength;
    return FormScaffold(
      title: 'Ubah Kata Sandi',
      formKey: _form,
      submitLabel: 'Simpan kata sandi',
      onSubmit: _save,
      children: [
        AppTextField(
            controller: _old,
            label: 'Kata sandi lama',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
        FormRow(children: [
          AppTextField(
              controller: _new,
              label: 'Kata sandi baru',
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              validator: (v) => (v == null || v.length < minPass)
                  ? 'Minimal $minPass karakter'
                  : null),
          AppTextField(
              controller: _confirm,
              label: 'Konfirmasi kata sandi baru',
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              validator: (v) =>
                  v != _new.text ? 'Kata sandi tidak sama' : null),
        ]),
      ],
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    const labels = {
      'persetujuan': ('Status persetujuan', 'Informasi disetujui atau ditolak'),
      'pengingat': (
        'Pengingat pengembalian',
        'Pengingat jadwal pengembalian barang'
      ),
      'stok': (
        'Informasi stok dan permintaan',
        'Permintaan barang habis pakai dan stok menipis'
      ),
      'email': (
        'Salin ke email',
        'Kirim notifikasi penting ke email (simulasi)'
      ),
    };
    return AppPage(
      title: 'Pengaturan Notifikasi',
      body: PageList(children: [
        ResponsiveBody(
          maxWidth: 720,
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final e in labels.entries)
                SwitchListTile(
                  title: Text(e.value.$1,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.value.$2),
                  value: s.prefs[e.key] ?? false,
                  onChanged: (v) => s.setPref(e.key, v),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Informasi Aplikasi',
      body: PageList(children: [
        ResponsiveBody(
          maxWidth: 720,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Column(children: [
                SipintarLogo(size: 72),
                SizedBox(height: 12),
                Text('SIPINTAR',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
                Text(
                    'Sistem Informasi Peminjaman dan Inventaris Barang Sekolah',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
            SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Tentang', rows: [
              ('Versi', '0.2.0 (frontend)'),
              ('Platform', 'Flutter Web dan Android'),
              ('Data', 'Dummy lokal, tanpa backend'),
              ('Chatbot', 'Simulasi jawaban dummy'),
              ('Forecasting', 'Simulasi, bukan model ML sungguhan'),
              ('Verifikasi wajah', 'Simulasi tampilan kamera'),
            ]),
          ]),
        ),
      ]),
    );
  }
}
