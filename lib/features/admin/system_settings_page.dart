import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/account/profile_page.dart';
import 'package:sipintar/features/admin/role_management_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

void _audit(BuildContext c, String detail) {
  final me = c.read<AuthStore>().currentUser;
  c.read<AuditStore>().log(me?.name ?? 'Admin', me?.role.label ?? 'Admin', 'Pengaturan', detail);
}

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final items = <(IconData, String, String, Widget)>[
      (Icons.info_outline, 'Informasi aplikasi', 'Versi dan keterangan aplikasi', const AppInfoPage()),
      (Icons.tune, 'Pengaturan umum', '${s.schoolName} - ${s.academicYear}', const GeneralSettingsPage()),
      (Icons.security, 'Pengaturan keamanan', 'Kata sandi minimal ${s.minPasswordLength} karakter', const SecuritySettingsPage()),
      (Icons.timer_outlined, 'Batas waktu booking', 'Persetujuan Sapras maksimal ${s.approvalHours} jam', const BookingSettingsPage()),
      (Icons.notifications_none, 'Pengaturan notifikasi', 'Jenis notifikasi sistem', const NotificationSettingsPage()),
      (Icons.manage_accounts_outlined, 'Pengaturan akun', 'Profil dan kata sandi Admin', const AccountSettingsPage()),
      (Icons.admin_panel_settings_outlined, 'Pengaturan hak akses', 'Izin menu dan fitur tiap role', const RoleManagementPage()),
    ];
    return AppPage(
      title: 'Pengaturan Sistem',
      body: PageList(children: [
        ResponsiveGrid(minItemWidth: 320, children: [
          for (final i in items)
            AppCard(
              onTap: () => push(context, i.$4),
              child: Row(children: [
                CircleAvatar(backgroundColor: AppColors.blue.withOpacity(0.12), child: Icon(i.$1, color: AppColors.navy)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(i.$3, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ]),
                ),
                const Icon(Icons.chevron_right),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});
  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  final _form = GlobalKey<FormState>();
  late final _school = TextEditingController(text: context.read<SettingsStore>().schoolName);
  late final _year = TextEditingController(text: context.read<SettingsStore>().academicYear);

  @override
  void dispose() {
    _school.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Pengaturan Umum',
        formKey: _form,
        submitLabel: 'Simpan pengaturan',
        onSubmit: () {
          if (!_form.currentState!.validate()) return;
          context.read<SettingsStore>().update(school: _school.text.trim(), year: _year.text.trim());
          _audit(context, 'Mengubah pengaturan umum');
          snack(context, 'Pengaturan umum disimpan.');
          Navigator.of(context).pop();
        },
        children: [
          FormRow(children: [
            AppTextField(controller: _school, label: 'Nama sekolah', icon: Icons.school_outlined, validator: (v) => (v == null || v.trim().length < 3) ? 'Wajib diisi' : null),
            AppTextField(controller: _year, label: 'Tahun ajaran', icon: Icons.calendar_today_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
          ]),
          const AppCard(child: Text('Bahasa aplikasi: Bahasa Indonesia (tetap).', style: TextStyle(fontSize: 13))),
        ],
      );
}

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});
  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  late int _min = context.read<SettingsStore>().minPasswordLength;
  late int _session = context.read<SettingsStore>().sessionMinutes;
  late bool _lock = context.read<SettingsStore>().lockoutEnabled;

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Pengaturan Keamanan',
        submitLabel: 'Simpan pengaturan',
        onSubmit: () {
          context.read<SettingsStore>().update(minPass: _min, session: _session, lockout: _lock);
          _audit(context, 'Mengubah pengaturan keamanan');
          snack(context, 'Pengaturan keamanan disimpan.');
          Navigator.of(context).pop();
        },
        children: [
          FormRow(children: [
            AppDropdown<int>(
              label: 'Panjang kata sandi minimal',
              icon: Icons.password,
              value: _min,
              items: [for (final n in const [6, 8, 10, 12]) DropdownMenuItem(value: n, child: Text('$n karakter'))],
              onChanged: (v) => setState(() => _min = v ?? _min),
            ),
            AppDropdown<int>(
              label: 'Batas sesi tidak aktif',
              icon: Icons.timelapse,
              value: _session,
              items: [for (final n in const [15, 30, 60, 120]) DropdownMenuItem(value: n, child: Text('$n menit'))],
              onChanged: (v) => setState(() => _session = v ?? _session),
            ),
          ]),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Kunci akun setelah 5 kali gagal masuk'),
              subtitle: const Text('Mencegah percobaan masuk berulang'),
              value: _lock,
              onChanged: (v) => setState(() => _lock = v),
            ),
          ),
        ],
      );
}

class BookingSettingsPage extends StatefulWidget {
  const BookingSettingsPage({super.key});
  @override
  State<BookingSettingsPage> createState() => _BookingSettingsPageState();
}

class _BookingSettingsPageState extends State<BookingSettingsPage> {
  late double _h = context.read<SettingsStore>().approvalHours.toDouble();

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Batas Waktu Booking',
        submitLabel: 'Simpan batas waktu',
        onSubmit: () {
          context.read<SettingsStore>().setApprovalHours(_h.round());
          _audit(context, 'Mengubah batas booking menjadi ${_h.round()} jam');
          snack(context, 'Batas waktu booking disimpan: ${_h.round()} jam.');
          Navigator.of(context).pop();
        },
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Batas waktu persetujuan Sapras', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pengajuan yang tidak diproses dalam batas ini otomatis menjadi booking kedaluwarsa.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Center(child: Text('${_h.round()} jam', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.navy))),
              Slider(value: _h, min: 1, max: 48, divisions: 47, label: '${_h.round()} jam', onChanged: (v) => setState(() => _h = v)),
            ]),
          ),
        ],
      );
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Pengaturan Akun',
        body: PageList(children: [
          ResponsiveBody(
            maxWidth: 720,
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit profil'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const EditProfilePage())),
                ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Ubah kata sandi'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const ChangePasswordPage())),
                ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Pengaturan notifikasi'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const NotificationSettingsPage())),
              ]),
            ),
          ),
        ]),
      );
}
