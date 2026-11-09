import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/scan_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class HandoverPage extends StatelessWidget {
  const HandoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final todo = store.withStatus({LoanStatus.disetujui});
    final done = store.loans.where((l) => l.handoverAt != null).toList()
      ..sort((a, b) => b.handoverAt!.compareTo(a.handoverAt!));

    Widget card(LoanRequest l, bool open) => RowCard(
          leading: ItemImage(iconKey: l.lines.first.iconKey, size: 48),
          title: '${l.id} - ${l.borrower.name}',
          subtitle: '${l.borrower.role.label} - ${l.summary}',
          extra: [
            Text(Fmt.range(l.start, l.end),
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary))
          ],
          trailing: open
              ? const Icon(Icons.chevron_right)
              : StatusBadge.status(l.status),
          onTap: open
              ? () => push(context, HandoverDetailPage(loanId: l.id))
              : null,
        );

    return DefaultTabController(
      length: 2,
      child: AppPage(
        title: 'Penyerahan Barang',
        bottom: TabBar(tabs: [
          Tab(text: 'Harus diserahkan (${todo.length})'),
          const Tab(text: 'Riwayat penyerahan')
        ]),
        body: TabBarView(children: [
          PageList(children: [
            if (todo.isEmpty)
              const SizedBox(
                  height: 280,
                  child: EmptyState(
                      icon: Icons.outbox_outlined,
                      title: 'Tidak ada penyerahan',
                      message:
                          'Peminjaman yang sudah disetujui akan muncul di sini.'))
            else
              ResponsiveGrid(
                  minItemWidth: 420,
                  children: [for (final l in todo) card(l, true)]),
          ]),
          PageList(children: [
            if (done.isEmpty)
              const SizedBox(
                  height: 280,
                  child: EmptyState(
                      icon: Icons.history,
                      title: 'Belum ada riwayat',
                      message:
                          'Penyerahan yang telah dikonfirmasi akan tercatat di sini.'))
            else
              ResponsiveGrid(
                  minItemWidth: 420,
                  children: [for (final l in done) card(l, false)]),
          ]),
        ]),
      ),
    );
  }
}

class HandoverDetailPage extends StatefulWidget {
  final String loanId;
  const HandoverDetailPage({super.key, required this.loanId});
  @override
  State<HandoverDetailPage> createState() => _HandoverDetailPageState();
}

class _HandoverDetailPageState extends State<HandoverDetailPage> {
  final Map<String, List<String>> _scanned = {};
  late final TextEditingController _receiver;
  bool _proof = false;
  final DateTime _time = DateTime.now();

  @override
  void initState() {
    super.initState();
    final l = context.read<LoanStore>().byId(widget.loanId);
    _receiver = TextEditingController(text: l?.borrower.name ?? '');
  }

  @override
  void dispose() {
    _receiver.dispose();
    super.dispose();
  }

  Future<void> _scan(LoanRequest l, LoanLine line) async {
    final inv = context.read<InventoryStore>();
    final taken = _scanned.values.expand((e) => e).toSet();
    final item = inv.itemById(line.itemId);
    final candidates = item?.units
            .where((u) => u.borrowable && !taken.contains(u.code))
            .toList() ??
        [];
    if (candidates.isEmpty) {
      snack(context,
          'Tidak ada unit ${line.itemName} yang tersedia untuk diserahkan.',
          error: true);
      return;
    }
    final code = await showScanSheet(context, code: candidates.first.code);
    if (code == null || !mounted) return;
    setState(() => (_scanned[line.itemId] ??= []).add(code));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LoanStore>().byId(widget.loanId);
    if (l == null) {
      return const AppPage(
          title: 'Penyerahan',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Data tidak ditemukan',
              message: ''));
    }
    final allDone =
        l.lines.every((x) => (_scanned[x.itemId]?.length ?? 0) == x.qty);
    final canConfirm = allDone && _receiver.text.trim().isNotEmpty && _proof;

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Scan barcode unit'),
      const SizedBox(height: 8),
      for (final x in l.lines)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ItemImage(iconKey: x.iconKey, size: 44),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(x.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                StatusBadge('${_scanned[x.itemId]?.length ?? 0}/${x.qty} unit',
                    tone: (_scanned[x.itemId]?.length ?? 0) == x.qty
                        ? BadgeTone.success
                        : BadgeTone.warning),
              ]),
              if ((_scanned[x.itemId] ?? []).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final c in _scanned[x.itemId]!)
                      Chip(
                          avatar: const Icon(Icons.qr_code_2, size: 16),
                          label: Text(c),
                          visualDensity: VisualDensity.compact)
                  ]),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                onPressed: (_scanned[x.itemId]?.length ?? 0) >= x.qty
                    ? null
                    : () => _scan(l, x),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan barcode unit'),
              ),
            ]),
          ),
        ),
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BorrowerCard(l.borrower, title: 'Peminjam'),
      const SizedBox(height: AppSpacing.md),
      InfoCard(title: 'Jadwal', rows: [
        ('Mulai', Fmt.dateTime(l.start)),
        ('Selesai', Fmt.dateTime(l.end)),
        ('Tujuan', l.purpose)
      ]),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Konfirmasi penyerahan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          AppTextField(
              controller: _receiver,
              label: 'Nama penerima',
              icon: Icons.person_outline,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          Text('Waktu penyerahan: ${Fmt.dateTime(_time)}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          if (_proof)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.photo, color: AppColors.success),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Foto bukti penyerahan tersimpan (simulasi)',
                        style: TextStyle(fontSize: 13))),
                TextButton(
                    onPressed: () => setState(() => _proof = false),
                    child: const Text('Hapus')),
              ]),
            )
          else
            OutlinedButton.icon(
                onPressed: () => setState(() => _proof = true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ambil foto bukti (simulasi)')),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Konfirmasi penyerahan',
            icon: Icons.check_circle_outline,
            onPressed: canConfirm
                ? () async {
                    final ok = await confirm(context,
                        title: 'Konfirmasi penyerahan?',
                        message:
                            'Unit akan tercatat sedang dipinjam oleh ${l.borrower.name}.',
                        confirmLabel: 'Konfirmasi');
                    if (!ok || !context.mounted) return;
                    final List<String> codes = [
                      for (final x in l.lines)
                        ...(_scanned[x.itemId] ?? <String>[])
                    ];
                    final err = context
                        .read<LoanStore>()
                        .handover(l, _receiver.text, codes);
                    if (err != null) {
                      snack(context, err, error: true);
                      return;
                    }
                    snack(context, 'Penyerahan ${l.id} dikonfirmasi.');
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          if (!canConfirm)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Lengkapi scan semua unit, nama penerima, dan foto bukti.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary))),
        ]),
      ),
    ]);

    return AppPage(
        title: 'Penyerahan ${l.id}',
        body: PageList(children: [TwoPane(left: left, right: right)]));
  }
}
