import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/scan_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final todo = store.withStatus(
        {LoanStatus.sedangDipinjam, LoanStatus.menungguPengembalian});
    final done = store.withStatus({LoanStatus.selesai});

    Widget card(LoanRequest l) {
      final late =
          l.end.isBefore(DateTime.now()) && l.status != LoanStatus.selesai;
      return RowCard(
        leading: ItemImage(iconKey: l.lines.first.iconKey, size: 48),
        title: '${l.id} - ${l.borrower.name}',
        subtitle: '${l.borrower.role.label} - ${l.summary}',
        extra: [
          Text(
              l.status == LoanStatus.selesai
                  ? 'Dikembalikan ${Fmt.dateTime(l.returnedAt ?? l.end)}'
                  : 'Jatuh tempo ${Fmt.dateTime(l.end)}',
              style: TextStyle(
                  fontSize: 12.5,
                  color: late ? AppColors.danger : AppColors.textSecondary,
                  fontWeight: late ? FontWeight.w700 : FontWeight.w500)),
        ],
        trailing: StatusBadge.status(l.status),
        onTap: () => push(context, ReturnDetailPage(loanId: l.id)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: AppPage(
        title: 'Pengembalian Barang',
        bottom: TabBar(tabs: [
          Tab(text: 'Harus dikembalikan (${todo.length})'),
          const Tab(text: 'Riwayat pengembalian')
        ]),
        body: TabBarView(children: [
          PageList(children: [
            if (todo.isEmpty)
              const SizedBox(
                  height: 280,
                  child: EmptyState(
                      icon: Icons.move_to_inbox_outlined,
                      title: 'Tidak ada pengembalian',
                      message:
                          'Barang yang sedang dipinjam akan muncul di sini.'))
            else
              ResponsiveGrid(
                  minItemWidth: 420, children: [for (final l in todo) card(l)]),
          ]),
          PageList(children: [
            if (done.isEmpty)
              const SizedBox(
                  height: 280,
                  child: EmptyState(
                      icon: Icons.history,
                      title: 'Belum ada riwayat',
                      message:
                          'Pengembalian yang dikonfirmasi akan tercatat di sini.'))
            else
              ResponsiveGrid(
                  minItemWidth: 420, children: [for (final l in done) card(l)]),
          ]),
        ]),
      ),
    );
  }
}

class ReturnDetailPage extends StatefulWidget {
  final String loanId;
  const ReturnDetailPage({super.key, required this.loanId});
  @override
  State<ReturnDetailPage> createState() => _ReturnDetailPageState();
}

class _ReturnDetailPageState extends State<ReturnDetailPage> {
  final Map<String, ItemCondition> _cond = {};
  final Set<String> _verified = {};
  final _note = TextEditingController();
  String? _noteErr;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LoanStore>();
    final inv = context.watch<InventoryStore>();
    final l = store.byId(widget.loanId);
    if (l == null) {
      return const AppPage(
          title: 'Pengembalian',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Data tidak ditemukan',
              message: ''));
    }
    final readOnly = l.status == LoanStatus.selesai;
    final allVerified = l.unitCodes.every(_verified.contains);
    final damaged = l.unitCodes
        .any((c) => (_cond[c] ?? ItemCondition.layak) != ItemCondition.layak);

    Widget unitRow(String code) {
      final ref = inv.findByCode(code);
      final ok = readOnly || _verified.contains(code);
      final cur = readOnly
          ? (l.returnConditions[code] ?? ItemCondition.layak)
          : (_cond[code] ?? ItemCondition.layak);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ItemImage(iconKey: ref?.item.iconKey ?? 'umum', size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref?.item.name ?? code,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(code,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5)),
                    ]),
              ),
              StatusBadge(ok ? 'Terverifikasi' : 'Belum dipindai',
                  tone: ok ? BadgeTone.success : BadgeTone.warning),
            ]),
            const SizedBox(height: 10),
            FormRow(breakpoint: 420, children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                onPressed: readOnly || ok
                    ? null
                    : () async {
                        final c = await showScanSheet(context, code: code);
                        if (c != null && mounted) {
                          setState(() => _verified.add(c));
                        }
                      },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan barcode'),
              ),
              AppDropdown<ItemCondition>(
                label: 'Kondisi setelah kembali',
                value: cur,
                items: [
                  for (final c in ItemCondition.values)
                    DropdownMenuItem(value: c, child: Text(c.label))
                ],
                onChanged: readOnly
                    ? null
                    : (v) =>
                        setState(() => _cond[code] = v ?? ItemCondition.layak),
              ),
            ]),
          ]),
        ),
      );
    }

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Pemeriksaan unit'),
      const SizedBox(height: 8),
      if (l.unitCodes.isEmpty)
        const AppCard(
            child: Text('Belum ada unit yang diserahkan.',
                style: TextStyle(color: AppColors.textSecondary)))
      else
        for (final c in l.unitCodes) unitRow(c),
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BorrowerCard(l.borrower, title: 'Peminjam'),
      const SizedBox(height: AppSpacing.md),
      InfoCard(title: 'Peminjaman', rows: [
        ('Jadwal', Fmt.range(l.start, l.end)),
        ('Penerima', l.receiver ?? '-'),
        (
          'Diserahkan',
          l.handoverAt == null ? '-' : Fmt.dateTime(l.handoverAt!)
        ),
        if (l.returnedAt != null) ('Dikembalikan', Fmt.dateTime(l.returnedAt!)),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (readOnly)
        InfoCard(
            title: 'Catatan kerusakan',
            rows: [('Catatan', l.damageNote ?? 'Tidak ada kerusakan.')])
      else
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Konfirmasi pengembalian',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText:
                      'Catatan kerusakan${damaged ? ' (wajib)' : ' (opsional)'}',
                  errorText: _noteErr,
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Konfirmasi pengembalian',
              icon: Icons.check_circle_outline,
              onPressed: () async {
                if (!allVerified) {
                  snack(context, 'Scan barcode seluruh unit terlebih dahulu.',
                      error: true);
                  return;
                }
                if (damaged && _note.text.trim().length < 5) {
                  setState(
                      () => _noteErr = 'Jelaskan kerusakan yang ditemukan');
                  return;
                }
                setState(() => _noteErr = null);
                final ok = await confirm(context,
                    title: 'Konfirmasi pengembalian?',
                    message: damaged
                        ? 'Unit rusak akan dicatat otomatis pada daftar perbaikan.'
                        : 'Seluruh unit akan kembali tersedia.',
                    confirmLabel: 'Konfirmasi');
                if (!ok || !context.mounted) return;
                store.completeReturn(
                    l,
                    {
                      for (final c in l.unitCodes)
                        c: _cond[c] ?? ItemCondition.layak
                    },
                    _note.text);
                snack(context, 'Pengembalian ${l.id} dikonfirmasi.');
                Navigator.of(context).pop();
              },
            ),
          ]),
        ),
    ]);

    return AppPage(
        title: 'Pengembalian ${l.id}',
        body: PageList(children: [TwoPane(left: left, right: right)]));
  }
}
