import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_approvals_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ConsumableApprovalsPage extends StatelessWidget {
  const ConsumableApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    List<ConsumableRequest> by(Set<ConsumableStatus> s) =>
        store.requests.where((r) => s.contains(r.status)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final waiting = by({ConsumableStatus.menunggu});
    final approved = by({ConsumableStatus.disetujui});
    final history = by({ConsumableStatus.diserahkan, ConsumableStatus.ditolak});

    Widget list(List<ConsumableRequest> l, String empty) => PageList(children: [
          if (l.isEmpty)
            SizedBox(
                height: 280,
                child: EmptyState(
                    icon: Icons.rule_folder_outlined,
                    title: 'Tidak ada data',
                    message: empty))
          else
            ResponsiveGrid(minItemWidth: 420, children: [
              for (final r in l)
                RowCard(
                  leading: ItemImage(iconKey: r.lines.first.iconKey, size: 48),
                  title: '${r.id} - ${r.requester.name}',
                  subtitle:
                      '${r.requester.role.label} - ${r.requester.identityLabel} ${r.requester.identityValue}',
                  extra: [
                    Text(r.summary,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    Text(Fmt.dateTime(r.createdAt),
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary))
                  ],
                  trailing: StatusBadge.status(r.status),
                  onTap: () => push(
                      context, ConsumableApprovalDetailPage(requestId: r.id)),
                ),
            ]),
        ]);

    return DefaultTabController(
      length: 3,
      child: AppPage(
        title: 'Persetujuan Barang Habis Pakai',
        bottom:
            TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
          Tab(text: 'Menunggu (${waiting.length})'),
          Tab(text: 'Siap diserahkan (${approved.length})'),
          const Tab(text: 'Riwayat pengeluaran'),
        ]),
        body: TabBarView(children: [
          list(waiting, 'Permintaan baru akan muncul di sini.'),
          list(approved,
              'Permintaan yang disetujui dan siap diserahkan muncul di sini.'),
          list(history, 'Riwayat pengeluaran barang muncul di sini.'),
        ]),
      ),
    );
  }
}

class ConsumableApprovalDetailPage extends StatefulWidget {
  final String requestId;
  const ConsumableApprovalDetailPage({super.key, required this.requestId});
  @override
  State<ConsumableApprovalDetailPage> createState() =>
      _ConsumableApprovalDetailPageState();
}

class _ConsumableApprovalDetailPageState
    extends State<ConsumableApprovalDetailPage> {
  final Map<String, int> _approved = {};

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final m = store.requests.where((r) => r.id == widget.requestId);
    if (m.isEmpty) {
      return const AppPage(
          title: 'Detail Permintaan',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Permintaan tidak ditemukan',
              message: ''));
    }
    final r = m.first;
    final waiting = r.status == ConsumableStatus.menunggu;

    Widget line(ConsumableLine l) {
      final stock = store.itemById(l.itemId)?.stock ?? 0;
      final max = l.qty < stock ? l.qty : stock;
      final cur = _approved[l.itemId] ?? max;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ItemImage(iconKey: l.iconKey, size: 44),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(l.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 10),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge('Diminta ${l.qty} ${l.satuan}',
                      tone: BadgeTone.info),
                  StatusBadge('Stok $stock ${l.satuan}',
                      tone: stock >= l.qty
                          ? BadgeTone.success
                          : BadgeTone.warning),
                  if (waiting) ...[
                    const Text('Disetujui:',
                        style: TextStyle(color: AppColors.textSecondary)),
                    QtyStepper(
                        value: cur,
                        min: 0,
                        max: max,
                        onChanged: (v) =>
                            setState(() => _approved[l.itemId] = v)),
                  ] else
                    StatusBadge('Disetujui ${l.approved ?? 0} ${l.satuan}',
                        tone: (l.approved ?? 0) > 0
                            ? BadgeTone.success
                            : BadgeTone.danger),
                ]),
          ]),
        ),
      );
    }

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Barang diminta'),
      const SizedBox(height: 8),
      for (final l in r.lines) line(l),
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BorrowerCard(r.requester, title: 'Identitas pemohon'),
      const SizedBox(height: AppSpacing.md),
      InfoCard(title: 'Detail', rows: [
        ('Diajukan', Fmt.dateTime(r.createdAt)),
        ('Tujuan', r.purpose),
        ('Pengembalian', 'Tidak ada'),
        if (r.reason != null) ('Alasan penolakan', r.reason!),
        if (r.handedAt != null) ('Diserahkan', Fmt.dateTime(r.handedAt!)),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (waiting) ...[
        PrimaryButton(
          label: 'Setujui permintaan',
          icon: Icons.check,
          onPressed: () async {
            final amounts = {
              for (final l in r.lines)
                l.itemId: _approved[l.itemId] ??
                    ((store.itemById(l.itemId)?.stock ?? 0) < l.qty
                        ? (store.itemById(l.itemId)?.stock ?? 0)
                        : l.qty),
            };
            if (amounts.values.every((v) => v == 0)) {
              snack(context,
                  'Jumlah disetujui tidak boleh nol untuk semua barang.',
                  error: true);
              return;
            }
            final ok = await confirm(context,
                title: 'Setujui permintaan?',
                message: 'Stok baru berkurang setelah penyerahan dikonfirmasi.',
                confirmLabel: 'Setujui');
            if (!ok || !context.mounted) return;
            store.approve(r, amounts);
            snack(context, 'Permintaan ${r.id} disetujui.');
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger)),
          onPressed: () => push(
            context,
            RejectReasonPage(
              title: 'Tolak ${r.id}',
              presets: const [
                'Stok tidak mencukupi',
                'Jumlah melebihi batas permintaan',
                'Kebutuhan belum jelas'
              ],
              onSubmit: (reason) => store.reject(r, reason),
            ),
          ),
          icon: const Icon(Icons.close),
          label: const Text('Tolak'),
        ),
      ],
      if (r.status == ConsumableStatus.disetujui) ...[
        const AppCard(
            child: Text(
                'Stok otomatis berkurang setelah penyerahan dikonfirmasi.',
                style: TextStyle(fontSize: 13))),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Konfirmasi penyerahan',
          icon: Icons.outbox,
          onPressed: () async {
            final ok = await confirm(context,
                title: 'Konfirmasi penyerahan?',
                message:
                    'Barang diserahkan kepada ${r.requester.name} dan stok akan dikurangi.',
                confirmLabel: 'Konfirmasi');
            if (!ok || !context.mounted) return;
            final err = store.confirmHandover(r);
            snack(context, err ?? 'Penyerahan dikonfirmasi. Stok diperbarui.',
                error: err != null);
          },
        ),
      ],
    ]);

    return AppPage(
      title: 'Detail Permintaan',
      body: PageList(children: [
        AppCard(
            child: Row(children: [
          Expanded(
              child: Text(r.id,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy))),
          StatusBadge.status(r.status)
        ])),
        const SizedBox(height: AppSpacing.md),
        TwoPane(left: left, right: right),
      ]),
    );
  }
}
