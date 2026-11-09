import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class LoanApprovalsPage extends StatefulWidget {
  const LoanApprovalsPage({super.key});
  @override
  State<LoanApprovalsPage> createState() => _LoanApprovalsPageState();
}

class _LoanApprovalsPageState extends State<LoanApprovalsPage> {
  String _filter = 'Semua';

  Widget _card(BuildContext context, LoanStore store, LoanRequest l,
          {bool pending = false}) =>
      RowCard(
        leading: ItemImage(iconKey: l.lines.first.iconKey, size: 48),
        title: '${l.id} - ${l.borrower.name}',
        subtitle:
            '${l.borrower.role.label} - ${l.borrower.identityLabel} ${l.borrower.identityValue}',
        extra: [
          Text(l.summary,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          Text(Fmt.range(l.start, l.end),
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          if (l.faceVerified == true)
            const Row(children: [
              Icon(Icons.verified_user, size: 15, color: AppColors.success),
              SizedBox(width: 4),
              Text('Wajah terverifikasi',
                  style: TextStyle(fontSize: 12, color: AppColors.success))
            ]),
        ],
        trailing: pending
            ? CountdownBadge(
                deadline: store.deadlineOf(l), onExpired: store.checkExpiry)
            : StatusBadge.status(l.status),
        onTap: () => push(context, LoanApprovalDetailPage(loanId: l.id)),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final pending = store.withStatus({LoanStatus.menungguPersetujuan});
    pending.sort((a, b) => store.deadlineOf(a).compareTo(store.deadlineOf(b)));
    const decided = {
      LoanStatus.disetujui,
      LoanStatus.ditolak,
      LoanStatus.kedaluwarsa,
      LoanStatus.sedangDipinjam,
      LoanStatus.menungguPengembalian,
      LoanStatus.selesai
    };
    var hist = store.withStatus(decided);
    hist = switch (_filter) {
      'Disetujui' => hist
          .where((l) =>
              l.status != LoanStatus.ditolak &&
              l.status != LoanStatus.kedaluwarsa)
          .toList(),
      'Ditolak' => hist.where((l) => l.status == LoanStatus.ditolak).toList(),
      'Booking kedaluwarsa' =>
        hist.where((l) => l.status == LoanStatus.kedaluwarsa).toList(),
      _ => hist,
    };
    return DefaultTabController(
      length: 2,
      child: AppPage(
        title: 'Persetujuan Peminjaman',
        bottom: TabBar(tabs: [
          Tab(text: 'Menunggu (${pending.length})'),
          const Tab(text: 'Riwayat persetujuan')
        ]),
        body: TabBarView(children: [
          PageList(children: [
            AppCard(
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Row(children: [
                const Icon(Icons.timer_outlined, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Pengajuan harus diproses dalam ${context.read<SettingsStore>().approvalHours} jam sejak pengajuan, jika tidak booking kedaluwarsa otomatis.',
                        style: const TextStyle(fontSize: 13))),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pending.isEmpty)
              const SizedBox(
                  height: 260,
                  child: EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'Tidak ada pengajuan',
                      message:
                          'Pengajuan yang menunggu persetujuan akan muncul di sini.'))
            else
              ResponsiveGrid(minItemWidth: 420, children: [
                for (final l in pending) _card(context, store, l, pending: true)
              ]),
          ]),
          PageList(children: [
            FilterRow(
                label: 'Hasil',
                options: const [
                  'Semua',
                  'Disetujui',
                  'Ditolak',
                  'Booking kedaluwarsa'
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v)),
            const SizedBox(height: 8),
            if (hist.isEmpty)
              const SizedBox(
                  height: 240,
                  child: EmptyState(
                      icon: Icons.history,
                      title: 'Belum ada riwayat',
                      message: 'Riwayat persetujuan akan muncul di sini.'))
            else
              ResponsiveGrid(
                  minItemWidth: 420,
                  children: [for (final l in hist) _card(context, store, l)]),
          ]),
        ]),
      ),
    );
  }
}

class LoanApprovalDetailPage extends StatelessWidget {
  final String loanId;
  const LoanApprovalDetailPage({super.key, required this.loanId});

  Future<void> _approve(BuildContext context, LoanRequest l) async {
    final ok = await confirm(context,
        title: 'Setujui pengajuan?',
        message: 'Peminjaman ${l.id} oleh ${l.borrower.name} akan disetujui.',
        confirmLabel: 'Setujui');
    if (!ok || !context.mounted) return;
    final err = context.read<LoanStore>().approve(l);
    if (err != null) {
      snack(context, err, error: true);
    } else {
      snack(context, 'Pengajuan ${l.id} disetujui.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final inv = context.watch<InventoryStore>();
    final l = store.byId(loanId);
    if (l == null) {
      return const AppPage(
          title: 'Detail Pengajuan',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Pengajuan tidak ditemukan',
              message: ''));
    }
    final isPending = l.status == LoanStatus.menungguPersetujuan;

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BorrowerCard(l.borrower, title: 'Identitas peminjam'),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daftar barang',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final x in l.lines)
            Builder(builder: (_) {
              final avail = inv.itemById(x.itemId)?.available ?? 0;
              final short = isPending && avail < x.qty;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  ItemImage(iconKey: x.iconKey, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(x.itemName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (isPending)
                            Text('Tersedia $avail unit',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: short
                                        ? AppColors.danger
                                        : AppColors.textSecondary)),
                        ]),
                  ),
                  Text('${x.qty} unit',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              );
            }),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      InfoCard(title: 'Jadwal dan tujuan', rows: [
        ('Mulai', Fmt.dateTime(l.start)),
        ('Selesai', Fmt.dateTime(l.end)),
        ('Tujuan', l.purpose),
        ('Diajukan', Fmt.dateTime(l.submittedAt)),
      ]),
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Row(children: [
          Icon(l.faceVerified == true ? Icons.verified_user : Icons.gpp_bad,
              color: l.faceVerified == true
                  ? AppColors.success
                  : AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hasil verifikasi wajah',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Text(
                  l.faceVerified == true
                      ? 'Berhasil - kecocokan ${((l.faceScore ?? 0) * 100).round()}%'
                      : 'Belum berhasil',
                  style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      if (isPending)
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Batas waktu persetujuan',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            CountdownBadge(
                deadline: store.deadlineOf(l),
                big: true,
                onExpired: store.checkExpiry),
          ]),
        ),
      if (l.rejectReason != null) ...[
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
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Riwayat status',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          LoanTimeline(l.events),
        ]),
      ),
      if (isPending) ...[
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
            label: 'Setujui',
            icon: Icons.check,
            onPressed: () => _approve(context, l)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger)),
          onPressed: () => push(
            context,
            RejectReasonPage(
              title: 'Tolak ${l.id}',
              presets: const [
                'Barang dibutuhkan untuk kegiatan sekolah lain',
                'Unit sedang dalam perbaikan',
                'Jadwal peminjaman bentrok',
                'Tujuan peminjaman belum jelas'
              ],
              onSubmit: (r) => context.read<LoanStore>().reject(l, r),
            ),
          ),
          icon: const Icon(Icons.close),
          label: const Text('Tolak'),
        ),
      ],
    ]);

    return AppPage(
      title: 'Detail Pengajuan',
      body: PageList(children: [
        AppCard(
            child: Row(children: [
          Expanded(
              child: Text(l.id,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy))),
          StatusBadge.status(l.status)
        ])),
        const SizedBox(height: AppSpacing.md),
        TwoPane(left: left, right: right),
      ]),
    );
  }
}

/// Form alasan penolakan (dipakai untuk peminjaman dan barang habis pakai).
class RejectReasonPage extends StatefulWidget {
  final String title;
  final List<String> presets;
  final void Function(String reason) onSubmit;
  const RejectReasonPage(
      {super.key,
      required this.title,
      required this.presets,
      required this.onSubmit});
  @override
  State<RejectReasonPage> createState() => _RejectReasonPageState();
}

class _RejectReasonPageState extends State<RejectReasonPage> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: widget.title,
        formKey: _form,
        submitLabel: 'Kirim penolakan',
        submitIcon: Icons.block,
        onSubmit: () async {
          if (!_form.currentState!.validate()) return;
          final ok = await confirm(context,
              title: 'Tolak pengajuan?',
              message: 'Alasan akan dikirim ke pemohon sebagai notifikasi.',
              confirmLabel: 'Tolak',
              danger: true);
          if (!ok || !context.mounted) return;
          widget.onSubmit(_reason.text.trim());
          snack(context, 'Pengajuan ditolak.');
          Navigator.of(context).pop();
        },
        children: [
          const Text('Pilih alasan cepat',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in widget.presets)
              ActionChip(
                  label: Text(p, style: const TextStyle(fontSize: 12.5)),
                  onPressed: () => setState(() => _reason.text = p)),
          ]),
          AppTextField(
              controller: _reason,
              label: 'Alasan penolakan',
              icon: Icons.edit_note,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Alasan minimal 8 karakter'
                  : null),
        ],
      );
}
