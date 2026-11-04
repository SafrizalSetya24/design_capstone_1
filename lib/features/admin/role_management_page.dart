import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class RoleManagementPage extends StatelessWidget {
  const RoleManagementPage({super.key});

  static const _desc = {
    UserRole.siswa: 'Meminjam barang dan meminta barang habis pakai. Identitas: NIS dan kelas.',
    UserRole.guru: 'Meminjam barang dan meminta barang habis pakai. Identitas: NIK dan jabatan/mapel.',
    UserRole.sapras: 'Mengelola inventaris, persetujuan, penyerahan, pengembalian, dan stok.',
    UserRole.admin: 'Mengelola pengguna, role, kategori, audit log, dan pengaturan sistem.',
  };
  static const _icons = {
    UserRole.siswa: Icons.school_outlined,
    UserRole.guru: Icons.person_pin_outlined,
    UserRole.sapras: Icons.inventory_2_outlined,
    UserRole.admin: Icons.admin_panel_settings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final s = context.watch<SettingsStore>();
    return AppPage(
      title: 'Role dan Hak Akses',
      body: PageList(children: [
        ResponsiveGrid(minItemWidth: 340, spacing: 16, children: [
          for (final r in UserRole.values)
            AppCard(
              onTap: () => push(context, RoleDetailPage(role: r)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(backgroundColor: AppColors.blue.withOpacity(0.12), child: Icon(_icons[r], color: AppColors.navy)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  const Icon(Icons.chevron_right),
                ]),
                const SizedBox(height: 10),
                Text(_desc[r]!, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  StatusBadge('${auth.countRole(r)} pengguna', tone: BadgeTone.info),
                  StatusBadge('${s.grantedCount(r)} izin aktif', tone: BadgeTone.success),
                ]),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class RoleDetailPage extends StatelessWidget {
  final UserRole role;
  const RoleDetailPage({super.key, required this.role});

  static const _groups = <String, List<String>>{
    'Fitur pengguna': ['pinjam_unit', 'minta_habis_pakai', 'riwayat', 'notifikasi', 'chatbot'],
    'Fitur Sapras': ['kelola_inventaris', 'persetujuan', 'penyerahan_pengembalian', 'laporan', 'forecasting'],
    'Fitur Admin': ['kelola_pengguna', 'kelola_role', 'audit_log', 'pengaturan_sistem'],
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final audit = context.read<AuditStore>();
    final me = context.read<AuthStore>().currentUser;
    return AppPage(
      title: 'Hak Akses ${role.label}',
      body: PageList(children: [
        if (role == UserRole.guru)
          AppCard(
            color: AppColors.blue.withOpacity(0.06),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: AppColors.blue),
              SizedBox(width: 10),
              Expanded(child: Text('Akses AI Chatbot untuk Guru mengikuti pengaturan di halaman ini dan tidak diasumsikan aktif.', style: TextStyle(fontSize: 13, height: 1.4))),
            ]),
          ),
        if (role == UserRole.admin)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppCard(child: Text('Admin tidak memiliki menu chatbot dan forecasting (dikunci).', style: TextStyle(fontSize: 13))),
          ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveGrid(minItemWidth: 420, spacing: 16, children: [
          for (final g in _groups.entries)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text(g.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                for (final k in g.value)
                  SwitchListTile(
                    title: Text(SettingsStore.permissionLabels[k]!, style: const TextStyle(fontSize: 14.5)),
                    subtitle: s.isLocked(role, k) ? const Text('Dikunci untuk role ini', style: TextStyle(fontSize: 12)) : null,
                    value: s.can(role, k),
                    onChanged: s.isLocked(role, k)
                        ? null
                        : (v) {
                            s.setPermission(role, k, v);
                            audit.log(me?.name ?? 'Admin', me?.role.label ?? 'Admin', 'Hak akses', '${v ? 'Mengaktifkan' : 'Menonaktifkan'} "${SettingsStore.permissionLabels[k]}" untuk ${role.label}');
                          },
                  ),
              ]),
            ),
        ]),
      ]),
    );
  }
}
