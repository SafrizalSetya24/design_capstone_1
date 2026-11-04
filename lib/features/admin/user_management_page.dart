import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/auth/register_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _q = '';
  String _role = 'Semua';
  String _status = 'Semua';

  Future<void> _toggle(Account a) async {
    final me = context.read<AuthStore>().currentUser;
    if (a.user.id == me?.id) {
      snack(context, 'Anda tidak dapat menonaktifkan akun sendiri.', error: true);
      return;
    }
    final ok = await confirm(context,
        title: a.active ? 'Nonaktifkan akun?' : 'Aktifkan akun?',
        message: a.active ? '${a.user.name} tidak dapat masuk ke aplikasi sampai diaktifkan kembali.' : '${a.user.name} dapat masuk kembali ke aplikasi.',
        confirmLabel: a.active ? 'Nonaktifkan' : 'Aktifkan',
        danger: a.active);
    if (!ok || !mounted) return;
    context.read<AuthStore>().toggleActive(a.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final list = auth.accounts.where((a) {
      final u = a.user;
      if (_q.isNotEmpty && !u.name.toLowerCase().contains(_q.toLowerCase()) && !u.email.toLowerCase().contains(_q.toLowerCase()) && !u.identityValue.contains(_q)) return false;
      if (_role != 'Semua' && u.role.label != _role) return false;
      if (_status == 'Aktif' && !a.active) return false;
      if (_status == 'Nonaktif' && a.active) return false;
      return true;
    }).toList();

    return AppPage(
      title: 'Manajemen Pengguna',
      fab: FloatingActionButton.extended(
        onPressed: () => push(context, const UserFormPage()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah pengguna'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SimLoading(
        child: PageList(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SearchField(hint: 'Cari nama, email, atau NIS/NIK...', onChanged: (v) => setState(() => _q = v)),
              FilterRow(label: 'Role', options: ['Semua', ...UserRole.values.map((r) => r.label)], selected: _role, onSelected: (v) => setState(() => _role = v)),
              FilterRow(label: 'Status akun', options: const ['Semua', 'Aktif', 'Nonaktif'], selected: _status, onSelected: (v) => setState(() => _status = v)),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${list.length} pengguna', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ResponsiveTable(
            emptyText: 'Tidak ada pengguna yang cocok.',
            columns: const ['Nama', 'Role', 'Identitas', 'Email', 'Status', 'Aksi'],
            onRowTap: (i) => push(context, UserDetailPage(userId: list[i].user.id)),
            rows: [
              for (final a in list)
                [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.navy, child: Text(a.user.initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 10),
                    Flexible(child: Text(a.user.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                  cellText(a.user.role.label),
                  cellText('${a.user.identityLabel}: ${a.user.identityValue}'),
                  cellText(a.user.email),
                  StatusBadge(a.active ? 'Aktif' : 'Nonaktif', tone: a.active ? BadgeTone.success : BadgeTone.neutral),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => push(context, UserFormPage(userId: a.user.id))),
                    Switch(value: a.active, onChanged: (_) => _toggle(a)),
                  ]),
                ],
            ],
          ),
        ]),
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final a = auth.accountOf(userId);
    if (a == null) {
      return const AppPage(title: 'Detail Pengguna', body: EmptyState(icon: Icons.person_off_outlined, title: 'Pengguna tidak ditemukan', message: 'Akun mungkin sudah dihapus.'));
    }
    final u = a.user;
    final isMe = auth.currentUser?.id == u.id;

    return AppPage(
      title: 'Detail Pengguna',
      actions: [IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, UserFormPage(userId: u.id)))],
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left: AppCard(
            child: Column(children: [
              CircleAvatar(radius: 42, backgroundColor: AppColors.navy, child: Text(u.initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
              const SizedBox(height: 12),
              Text(u.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(u.email, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Center(child: IdentityBadge(user: u)),
              const SizedBox(height: 10),
              StatusBadge(a.active ? 'Akun aktif' : 'Akun nonaktif', tone: a.active ? BadgeTone.success : BadgeTone.neutral),
            ]),
          ),
          right: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InfoCard(title: u.profileSectionTitle, rows: [for (final f in u.profileFields) (f.label, f.value)]),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Informasi akun', rows: [
              ('Role', u.role.label),
              ('Dibuat', Fmt.date(a.created)),
              ('Login terakhir', a.lastLogin == null ? '-' : Fmt.dateTime(a.lastLogin!)),
              ('Email', a.emailVerified ? 'Terverifikasi' : 'Belum diverifikasi'),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: a.active ? AppColors.warning : AppColors.success, minimumSize: const Size(170, 48)),
                onPressed: isMe
                    ? null
                    : () async {
                        final ok = await confirm(context,
                            title: a.active ? 'Nonaktifkan akun?' : 'Aktifkan akun?',
                            message: '${u.name} ${a.active ? 'tidak akan dapat masuk' : 'dapat masuk kembali'} ke aplikasi.',
                            confirmLabel: a.active ? 'Nonaktifkan' : 'Aktifkan',
                            danger: a.active);
                        if (ok && context.mounted) auth.toggleActive(u.id);
                      },
                icon: Icon(a.active ? Icons.block : Icons.check_circle_outline),
                label: Text(a.active ? 'Nonaktifkan' : 'Aktifkan'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(170, 48)),
                onPressed: () async {
                  final ok = await confirm(context, title: 'Reset kata sandi?', message: 'Kata sandi ${u.name} akan diganti dengan kata sandi sementara (simulasi).', confirmLabel: 'Reset');
                  if (!ok || !context.mounted) return;
                  final tmp = auth.resetPasswordSim(u.id);
                  showDialog<void>(
                    context: context,
                    builder: (d) => AlertDialog(
                      icon: const Icon(Icons.vpn_key_outlined, color: AppColors.blue),
                      title: const Text('Kata sandi sementara'),
                      content: SelectableText('Berikan kata sandi ini kepada pengguna:\n\n$tmp'),
                      actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Selesai'))],
                    ),
                  );
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Reset kata sandi'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), minimumSize: const Size(170, 48)),
                onPressed: isMe
                    ? null
                    : () async {
                        final ok = await confirm(context, title: 'Hapus pengguna?', message: 'Akun ${u.name} akan dihapus permanen.', confirmLabel: 'Hapus', danger: true);
                        if (!ok || !context.mounted) return;
                        auth.deleteUser(u.id);
                        snack(context, 'Akun ${u.name} dihapus.');
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Form tambah/edit pengguna. Kolom identitas mengikuti role sehingga NIS dan NIK tidak tercampur.
class UserFormPage extends StatefulWidget {
  final String? userId;
  const UserFormPage({super.key, this.userId});
  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _form = GlobalKey<FormState>();
  late final AppUser? _edit = widget.userId == null ? null : context.read<AuthStore>().accountOf(widget.userId!)?.user;
  late UserRole _role = _edit?.role ?? UserRole.siswa;
  late final _name = TextEditingController(text: _edit?.name ?? '');
  late final _email = TextEditingController(text: _edit?.email ?? '');
  late final _identity = TextEditingController(text: _edit?.identityValue ?? '');
  late final _extra = TextEditingController(text: _edit?.role == UserRole.guru ? (_edit?.extraValue ?? '') : '');
  final _pass = TextEditingController();
  late String? _kelas = _edit?.role == UserRole.siswa ? _edit?.extraValue : null;

  @override
  void dispose() {
    for (final c in [_name, _email, _identity, _extra, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _idLabel => switch (_role) { UserRole.siswa => 'NIS', UserRole.guru => 'NIK', UserRole.sapras => 'ID Pegawai', UserRole.admin => 'ID Admin' };

  String? _validateIdentity(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$_idLabel wajib diisi';
    if (_role == UserRole.siswa && (t.length < 8 || t.length > 10)) return 'NIS terdiri dari 8-10 digit';
    if (_role == UserRole.guru && t.length != 16) return 'NIK terdiri dari 16 digit';
    if ((_role == UserRole.sapras || _role == UserRole.admin) && t.length < 4) return '$_idLabel minimal 4 karakter';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthStore>();
    final extra = _role == UserRole.siswa ? (_kelas ?? '') : (_role == UserRole.guru ? _extra.text : '');
    final err = _edit == null
        ? auth.addUser(role: _role, name: _name.text, email: _email.text, identity: _identity.text.trim(), extra: extra, password: _pass.text)
        : auth.updateUser(_edit!.id, name: _name.text, email: _email.text, extra: extra);
    if (err != null) {
      snack(context, err, error: true);
      return;
    }
    snack(context, _edit == null ? 'Pengguna ditambahkan.' : 'Data pengguna diperbarui.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final minPass = context.read<SettingsStore>().minPasswordLength;
    final editing = _edit != null;
    final numeric = _role == UserRole.siswa || _role == UserRole.guru;
    return FormScaffold(
      title: editing ? 'Edit Pengguna' : 'Tambah Pengguna',
      formKey: _form,
      submitLabel: editing ? 'Simpan perubahan' : 'Tambah pengguna',
      onSubmit: _save,
      children: [
        AppDropdown<UserRole>(
          label: 'Role',
          icon: Icons.verified_user_outlined,
          value: _role,
          items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label))],
          onChanged: editing
              ? null
              : (v) => setState(() {
                    _role = v ?? _role;
                    _identity.clear();
                    _extra.clear();
                    _kelas = null;
                  }),
        ),
        FormRow(children: [
          AppTextField(controller: _name, label: 'Nama lengkap', icon: Icons.person_outline, validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null),
          AppTextField(controller: _email, label: 'Email', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Masukkan email yang valid'),
        ]),
        FormRow(children: [
          AppTextField(
            key: ValueKey('id-$_role'),
            controller: _identity,
            label: _idLabel,
            icon: Icons.badge_outlined,
            readOnly: editing,
            hint: editing ? 'Tidak dapat diubah' : null,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            formatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            maxLength: _role == UserRole.siswa ? 10 : (_role == UserRole.guru ? 16 : 12),
            validator: _validateIdentity,
          ),
          if (_role == UserRole.siswa)
            AppDropdown.strings(
              label: 'Kelas',
              icon: Icons.school_outlined,
              value: _kelas,
              options: (_kelas == null || RegisterPageKelas.list.contains(_kelas)) ? RegisterPageKelas.list : [...RegisterPageKelas.list, _kelas!],
              onChanged: (v) => setState(() => _kelas = v),
              validator: (v) => v == null ? 'Pilih kelas' : null,
            )
          else if (_role == UserRole.guru)
            AppTextField(controller: _extra, label: 'Jabatan / mata pelajaran', icon: Icons.menu_book_outlined, validator: (v) => (v == null || v.trim().length < 3) ? 'Wajib diisi' : null)
          else
            AppTextField(controller: TextEditingController(text: _role.label), label: 'Jenis akun', icon: Icons.work_outline, readOnly: true),
        ]),
        if (!editing)
          AppTextField(controller: _pass, label: 'Kata sandi awal', icon: Icons.lock_outline, isPassword: true, validator: (v) => (v == null || v.length < minPass) ? 'Minimal $minPass karakter' : null),
      ],
    );
  }
}
