import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/face_verification/face_verification_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class LoanSuccessPage extends StatelessWidget {
  final String loanId;
  const LoanSuccessPage({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final l = store.byId(loanId);
    return SuccessView(
      title: 'Pengajuan berhasil dikirim',
      message:
          'Pengajuan ${l?.id ?? ''} menunggu persetujuan Sapras. Jika tidak diproses sebelum batas waktu, booking otomatis kedaluwarsa.',
      extra: l == null
          ? null
          : Column(children: [
              CountdownBadge(
                  deadline: store.deadlineOf(l),
                  big: true,
                  onExpired: store.checkExpiry),
              const SizedBox(height: 6),
              Text(
                  'Batas persetujuan Sapras (${context.read<SettingsStore>().approvalHours} jam)',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
            ]),
      primaryLabel: 'Lihat status pengajuan',
      onPrimary: (c) => Navigator.of(c).pushReplacement(
          MaterialPageRoute(builder: (_) => LoanDetailPage(loanId: loanId))),
      secondaryLabel: 'Kembali ke beranda',
      onSecondary: (c) {
        final shell = ShellScope.maybeOf(c);
        popToRoot(c);
        shell?.go('beranda');
      },
    );
  }
}

/// Halaman status peminjaman (milik peminjam).
class LoanDetailPage extends StatelessWidget {
  final String loanId;
  const LoanDetailPage({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final l = store.byId(loanId);
    if (l == null) {
      return const AppPage(
          title: 'Status Pengajuan',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Pengajuan tidak ditemukan',
              message: 'Data mungkin sudah tidak tersedia.'));
    }
    final hours = context.read<SettingsStore>().approvalHours;

    final header = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(l.id,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy))),
          StatusBadge.status(l.status),
        ]),
        if (l.status == LoanStatus.menungguPersetujuan) ...[
          const SizedBox(height: 14),
          Row(children: [
            CountdownBadge(
                deadline: store.deadlineOf(l),
                big: true,
                onExpired: store.checkExpiry),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Sisa waktu persetujuan Sapras (batas $hours jam).',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary))),
          ]),
        ],
        if (l.status == LoanStatus.menungguVerifikasiWajah) ...[
          const SizedBox(height: 12),
          const Text(
              'Pengajuan belum dikirim. Selesaikan verifikasi wajah terlebih dahulu.',
              style: TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w600)),
        ],
      ]),
    );

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Barang dipinjam',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final x in l.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                ItemImage(iconKey: x.iconKey, size: 40),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(x.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${x.qty} unit',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      InfoCard(title: 'Jadwal dan tujuan', rows: [
        ('Mulai', Fmt.dateTime(l.start)),
        ('Selesai', Fmt.dateTime(l.end)),
        ('Tujuan', l.purpose),
        ('Diajukan', Fmt.dateTime(l.submittedAt)),
      ]),
      if (l.rejectReason != null) ...[
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: AppColors.danger.withValues(alpha: 0.07),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Alasan penolakan',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.danger)),
            const SizedBox(height: 4),
            Text(l.rejectReason!),
          ]),
        ),
      ],
      if (l.unitCodes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Unit yang diserahkan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in l.unitCodes)
                Chip(label: Text(c), visualDensity: VisualDensity.compact)
            ]),
            if (l.receiver != null)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Penerima: ${l.receiver}',
                      style: const TextStyle(fontSize: 13))),
            if (l.handoverAt != null)
              Text('Waktu penyerahan: ${Fmt.dateTime(l.handoverAt!)}',
                  style: const TextStyle(fontSize: 13)),
            if (l.returnedAt != null)
              Text('Dikembalikan: ${Fmt.dateTime(l.returnedAt!)}',
                  style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ],
    ]);

    final face = l.faceVerified;
    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Row(children: [
          Icon(
              face == null
                  ? Icons.face_retouching_off
                  : (face ? Icons.verified_user : Icons.gpp_bad),
              color: face == null
                  ? AppColors.warning
                  : (face ? AppColors.success : AppColors.danger)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Verifikasi wajah',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Text(
                  face == null
                      ? 'Belum dilakukan'
                      : (face
                          ? 'Berhasil (${((l.faceScore ?? 0) * 100).round()}%)'
                          : 'Gagal, perlu diulang'),
                  style: const TextStyle(fontSize: 13)),
            ]),
          ),
          if (l.status == LoanStatus.menungguVerifikasiWajah)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(110, 40)),
              onPressed: () =>
                  push(context, FaceVerificationPage(loanId: l.id)),
              child: Text(face == false ? 'Ulangi' : 'Verifikasi'),
            ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Riwayat status',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          LoanTimeline(l.events),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      _SimPanel(loan: l),
    ]);

    return AppPage(
      title: 'Status Pengajuan',
      body: PageList(children: [
        header,
        const SizedBox(height: AppSpacing.md),
        TwoPane(left: left, right: right)
      ]),
    );
  }
}

class _SimPanel extends StatelessWidget {
  final LoanRequest loan;
  const _SimPanel({required this.loan});

  @override
  Widget build(BuildContext context) {
    final actions = switch (loan.status) {
      LoanStatus.menungguPersetujuan => [
          ('approve', 'Simulasikan disetujui Sapras'),
          ('reject', 'Simulasikan ditolak'),
          ('expire', 'Simulasikan batas waktu terlewati')
        ],
      LoanStatus.disetujui => [('handover', 'Simulasikan penyerahan barang')],
      LoanStatus.sedangDipinjam => [
          ('due', 'Simulasikan jatuh tempo pengembalian'),
          ('return', 'Simulasikan pengembalian')
        ],
      LoanStatus.menungguPengembalian => [
          ('return', 'Simulasikan pengembalian')
        ],
      _ => <(String, String)>[],
    };
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.science_outlined),
        title: const Text('Simulasi perubahan status (demo)',
            style: TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actions.isEmpty)
            const Text('Tidak ada simulasi untuk status ini.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (final a in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    final err = context.read<LoanStore>().simulate(loan, a.$1);
                    if (err != null) snack(context, err, error: true);
                  },
                  child: Text(a.$2),
                ),
              ),
        ],
      ),
    );
  }
}
