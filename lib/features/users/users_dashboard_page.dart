import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_detail_page.dart';
import 'package:sipintar/features/consumables/consumable_user_pages.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class UsersDashboardPage extends StatelessWidget {
  const UsersDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    final loans = context.watch<LoanStore>().forUser(user.id);
    final reqs = context.watch<ConsumableStore>().forUser(user.id);
    final settings = context.watch<SettingsStore>();
    final unread = context.watch<NotificationStore>().unread(user.id);
    final shell = ShellScope.maybeOf(context);

    const activeSet = {
      LoanStatus.disetujui,
      LoanStatus.sedangDipinjam,
      LoanStatus.menungguPengembalian
    };
    const pendingSet = {
      LoanStatus.menungguVerifikasiWajah,
      LoanStatus.verifikasiBerhasil,
      LoanStatus.menungguPersetujuan
    };
    final active = loans.where((l) => activeSet.contains(l.status)).length;
    final pending = loans.where((l) => pendingSet.contains(l.status)).length +
        reqs.where((r) => r.status == ConsumableStatus.menunggu).length;
    final done = loans.where((l) => l.status == LoanStatus.selesai).length +
        reqs.where((r) => r.status == ConsumableStatus.diserahkan).length;

    final first = user.name.split(',').first.trim().split(' ').first;

    final acts = <_Act>[
      for (final l in loans)
        _Act(l.submittedAt, '${l.id} - ${l.summary}', Fmt.range(l.start, l.end),
            StatusBadge.extractLabel(l.status), () => push(context, LoanDetailPage(loanId: l.id))),
      for (final r in reqs)
        _Act(
            r.createdAt,
            '${r.id} - ${r.summary}',
            'Barang habis pakai - ${Fmt.dateTime(r.createdAt)}',
            StatusBadge.extractLabel(r.status),
            () => push(context, ConsumableRequestDetailPage(requestId: r.id))),
    ]..sort((a, b) => b.time.compareTo(a.time));

    final menus = <_Menu>[
      _Menu(
          Icons.laptop_mac_rounded,
          'Barang Per Unit',
          'Pinjam laptop, proyektor, kamera',
          () => shell?.go('katalog', arg: 0)),
      _Menu(Icons.layers_outlined, 'Barang Habis Pakai',
          'Minta kertas, pulpen, spidol', () => shell?.go('katalog', arg: 1)),
      _Menu(Icons.history, 'Riwayat', 'Status dan transaksi Anda',
          () => shell?.go('riwayat')),
      _Menu(
          Icons.notifications_none,
          'Notifikasi',
          unread > 0 ? '$unread belum dibaca' : 'Tidak ada yang baru',
          () => shell?.go('notifikasi')),
      if (settings.can(user.role, 'chatbot'))
        _Menu(Icons.smart_toy_outlined, 'Asisten AI',
            'Tanya seputar inventaris', () => shell?.go('chatbot')),
    ];

    return AppPage(
      title: 'Beranda',
      body: SimLoading(
        child: PageList(children: [
          Text('Halo, $first',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Apa yang ingin Anda pinjam hari ini?',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TwoPane(
            leftFlex: 2,
            rightFlex: 3,
            left: _ProfileCard(user: user),
            right: StatGrid([
              StatCard(
                  icon: Icons.assignment_turned_in_outlined,
                  value: '$active',
                  label: 'Peminjaman aktif',
                  color: AppColors.blue),
              StatCard(
                  icon: Icons.hourglass_top_rounded,
                  value: '$pending',
                  label: 'Menunggu persetujuan',
                  color: AppColors.warning),
              StatCard(
                  icon: Icons.task_alt,
                  value: '$done',
                  label: 'Riwayat selesai',
                  color: AppColors.success),
            ], minItemWidth: 130),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Menu'),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveGrid(
              minItemWidth: 170,
              children: [for (final m in menus) _MenuTile(m)]),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader('Aktivitas terbaru',
              actionLabel: 'Lihat semua', onAction: () => shell?.go('riwayat')),
          const SizedBox(height: AppSpacing.sm),
          if (acts.isEmpty)
            const SizedBox(
                height: 220,
                child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada aktivitas',
                    message:
                        'Pengajuan peminjaman dan permintaan barang Anda akan muncul di sini.'))
          else
            ResponsiveGrid(minItemWidth: 380, children: [
              for (final a in acts.take(6))
                RowCard(
                    title: a.title,
                    subtitle: a.sub,
                    trailing: StatusBadge.fromStatus(a.status),
                    onTap: a.onTap),
            ]),
        ]),
      ),
    );
  }
}

class _Act {
  final DateTime time;
  final String title, sub, status;
  final VoidCallback onTap;
  _Act(this.time, this.title, this.sub, this.status, this.onTap);
}

class _Menu {
  final IconData icon;
  final String label, hint;
  final VoidCallback onTap;
  _Menu(this.icon, this.label, this.hint, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _Menu m;
  const _MenuTile(this.m);
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: m.onTap,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(m.icon, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(m.hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      );
}

/// Kartu profil: label identitas mengikuti role (Siswa: NIS + kelas, Guru: NIK + jabatan/mapel).
class _ProfileCard extends StatelessWidget {
  final AppUser user;
  const _ProfileCard({required this.user});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppSpacing.radius)),
        child: Row(children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Text(user.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              if (user.extraValue != null)
                Text('${user.extraLabel}: ${user.extraValue}',
                    style: const TextStyle(
                        color: Color(0xFFBFD3F5), fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              IdentityBadge(user: user, onDark: true),
            ]),
          ),
        ]),
      );
}
