import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ConsumableCatalogView extends StatefulWidget {
  const ConsumableCatalogView({super.key});
  @override
  State<ConsumableCatalogView> createState() => _ConsumableCatalogViewState();
}

class _ConsumableCatalogViewState extends State<ConsumableCatalogView> {
  String _q = '';
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final cats =
        context.watch<InventoryStore>().categoryNames(CategoryType.habisPakai);
    final list = store.items.where((i) {
      if (_q.isNotEmpty && !i.name.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      return _cat == 'Semua' || i.category == _cat;
    }).toList();
    return SimLoading(
      child: PageList(children: [
        SearchField(
            hint: 'Cari kertas, pulpen, spidol...',
            onChanged: (v) => setState(() => _q = v)),
        FilterRow(
            label: 'Kategori',
            options: ['Semua', ...cats],
            selected: _cat,
            onSelected: (v) => setState(() => _cat = v)),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          color: AppColors.blue.withValues(alpha: 0.06),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.blue),
            SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Barang habis pakai tidak dikembalikan, tanpa jadwal peminjaman, dan tidak memerlukan verifikasi wajah.',
                    style: TextStyle(fontSize: 13))),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          const SizedBox(
              height: 260,
              child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Barang tidak ditemukan',
                  message: 'Ubah kata kunci atau kategori.'))
        else
          ResponsiveGrid(minItemWidth: 330, children: [
            for (final i in list)
              AppCard(
                onTap: () => push(context, ConsumableDetailPage(itemId: i.id)),
                child: Row(children: [
                  ItemImage(iconKey: i.iconKey, size: 80),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Stok: ${i.stock} ${i.satuan}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, children: [
                            StatusBadge(
                                i.low ? 'Stok menipis' : 'Stok tersedia',
                                tone: i.low
                                    ? BadgeTone.warning
                                    : BadgeTone.success),
                          ]),
                        ]),
                  ),
                  TextButton(
                      onPressed: () =>
                          push(context, ConsumableDetailPage(itemId: i.id)),
                      child: const Text('Detail')),
                ]),
              ),
          ]),
      ]),
    );
  }
}

class ConsumableDetailPage extends StatelessWidget {
  final String itemId;
  const ConsumableDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final i = context.watch<ConsumableStore>().itemById(itemId);
    if (i == null) {
      return const AppPage(
          title: 'Detail Barang',
          body: EmptyState(
              icon: Icons.layers_outlined,
              title: 'Barang tidak ditemukan',
              message: 'Barang mungkin sudah dihapus.'));
    }
    return AppPage(
      title: 'Detail Barang Habis Pakai',
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left: ItemImage(iconKey: i.iconKey, size: 200, height: 220),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(i.name,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(i.category,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(i.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Informasi stok', rows: [
              ('Stok tersedia', '${i.stock} ${i.satuan}'),
              ('Satuan', i.satuan),
              ('Lokasi', i.location),
              ('Status', i.low ? 'Stok menipis' : 'Stok tersedia'),
            ]),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: i.stock > 0 ? 'Minta barang' : 'Stok habis',
              icon: Icons.add_shopping_cart,
              onPressed: i.stock > 0
                  ? () =>
                      push(context, ConsumableRequestFormPage(presetId: i.id))
                  : null,
            ),
          ]),
        ),
      ]),
    );
  }
}

class ConsumableRequestFormPage extends StatefulWidget {
  final String? presetId;
  const ConsumableRequestFormPage({super.key, this.presetId});
  @override
  State<ConsumableRequestFormPage> createState() =>
      _ConsumableRequestFormPageState();
}

class _ConsumableRequestFormPageState extends State<ConsumableRequestFormPage> {
  final _form = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  List<LineEntry> _lines = [];
  bool _linesError = false;

  @override
  void initState() {
    super.initState();
    final i = widget.presetId == null
        ? null
        : context.read<ConsumableStore>().itemById(widget.presetId!);
    if (i != null && i.stock > 0) {
      _lines = [
        LineEntry(
            id: i.id, name: i.name, iconKey: i.iconKey, max: _max(i), qty: 1)
      ];
    }
  }

  int _max(ConsumableItem i) => i.stock > 50 ? 50 : i.stock;

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  void _next() {
    final ok = _form.currentState!.validate();
    setState(() => _linesError = _lines.isEmpty);
    if (!ok || _lines.isEmpty) return;
    final store = context.read<ConsumableStore>();
    final cl = [
      for (final l in _lines)
        ConsumableLine(
            itemId: l.id,
            itemName: l.name,
            satuan: store.itemById(l.id)?.satuan ?? '',
            iconKey: l.iconKey,
            qty: l.qty),
    ];
    push(context,
        ConsumableRequestSummaryPage(lines: cl, purpose: _purpose.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final options = [
      for (final i in store.items.where((x) => x.stock > 0))
        LineOption(
            id: i.id,
            name: i.name,
            iconKey: i.iconKey,
            hint: '${i.stock} ${i.satuan}',
            max: _max(i)),
    ];
    return FormScaffold(
      title: 'Permintaan Barang Habis Pakai',
      formKey: _form,
      submitLabel: 'Lanjut ke ringkasan',
      submitIcon: Icons.arrow_forward,
      onSubmit: _next,
      children: [
        AppCard(
          color: AppColors.blue.withValues(alpha: 0.06),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.blue),
            SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Tidak memerlukan verifikasi wajah dan tidak memiliki jadwal pengembalian.',
                    style: TextStyle(fontSize: 13))),
          ]),
        ),
        const SectionHeader('Barang yang dibutuhkan'),
        ItemLinesEditor(
          options: options,
          lines: _lines,
          errorText: _linesError ? 'Tambahkan minimal satu barang.' : null,
          onChanged: (v) => setState(() {
            _lines = v;
            _linesError = false;
          }),
        ),
        AppTextField(
          controller: _purpose,
          label: 'Tujuan penggunaan',
          icon: Icons.notes,
          maxLines: 3,
          validator: (v) => (v == null || v.trim().length < 8)
              ? 'Tujuan minimal 8 karakter'
              : null,
        ),
      ],
    );
  }
}

class ConsumableRequestSummaryPage extends StatelessWidget {
  final List<ConsumableLine> lines;
  final String purpose;
  const ConsumableRequestSummaryPage(
      {super.key, required this.lines, required this.purpose});

  Future<void> _submit(BuildContext context) async {
    final ok = await confirm(context,
        title: 'Kirim permintaan?',
        message: 'Permintaan akan dikirim ke Sapras untuk diproses.',
        confirmLabel: 'Kirim');
    if (!ok || !context.mounted) return;
    final user = context.read<AuthStore>().currentUser!;
    final r = context
        .read<ConsumableStore>()
        .submit(Borrower.fromUser(user), lines, purpose);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessView(
        title: 'Permintaan berhasil dikirim',
        message:
            'Permintaan ${r.id} menunggu persetujuan Sapras. Stok baru berkurang setelah barang diserahkan.',
        primaryLabel: 'Lihat status permintaan',
        onPrimary: (c) => Navigator.of(c).pushReplacement(MaterialPageRoute(
            builder: (_) => ConsumableRequestDetailPage(requestId: r.id))),
        secondaryLabel: 'Kembali ke beranda',
        onSecondary: (c) {
          final shell = ShellScope.maybeOf(c);
          popToRoot(c);
          shell?.go('beranda');
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Ringkasan Permintaan',
      body: PageList(children: [
        TwoPane(
          left:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daftar barang',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    for (final l in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          ItemImage(iconKey: l.iconKey, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(l.itemName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                          Text('${l.qty} ${l.satuan}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                      ),
                  ]),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Tujuan penggunaan', rows: [('Tujuan', purpose)]),
          ]),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const AppCard(
              child: Text(
                  'Barang habis pakai tidak dikembalikan. Setelah disetujui, ambil barang di Ruang Sapras. Stok berkurang saat penyerahan dikonfirmasi.',
                  style: TextStyle(height: 1.5)),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
                label: 'Konfirmasi pengajuan',
                icon: Icons.send,
                onPressed: () => _submit(context)),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ubah permintaan')),
          ]),
        ),
      ]),
    );
  }
}

class ConsumableRequestDetailPage extends StatelessWidget {
  final String requestId;
  const ConsumableRequestDetailPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final matches = store.requests.where((r) => r.id == requestId);
    if (matches.isEmpty) {
      return const AppPage(
          title: 'Status Permintaan',
          body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Permintaan tidak ditemukan',
              message: 'Data mungkin sudah tidak tersedia.'));
    }
    final r = matches.first;
    final steps = <(String, bool, String?)>[
      ('Permintaan dikirim', true, Fmt.dateTime(r.createdAt)),
      if (r.status == ConsumableStatus.ditolak)
        ('Ditolak', true, r.reason)
      else ...[
        (
          'Disetujui Sapras',
          r.status == ConsumableStatus.disetujui ||
              r.status == ConsumableStatus.diserahkan,
          null
        ),
        (
          'Barang diserahkan',
          r.status == ConsumableStatus.diserahkan,
          r.handedAt == null ? null : Fmt.dateTime(r.handedAt!)
        ),
      ],
    ];
    return AppPage(
      title: 'Status Permintaan',
      body: PageList(children: [
        AppCard(
          child: Row(children: [
            Expanded(
                child: Text(r.id,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy))),
            StatusBadge.fromStatus(r.status.label),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        TwoPane(
          left:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Barang diminta',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 8),
                    for (final l in r.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          ItemImage(iconKey: l.iconKey, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(l.itemName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Diminta: ${l.qty} ${l.satuan}',
                                    style: const TextStyle(fontSize: 12.5)),
                                if (l.approved != null)
                                  Text('Disetujui: ${l.approved} ${l.satuan}',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700)),
                              ]),
                        ]),
                      ),
                  ]),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Detail', rows: [
              ('Tanggal', Fmt.dateTime(r.createdAt)),
              ('Tujuan', r.purpose),
              ('Pengembalian', 'Tidak ada (barang habis pakai)'),
              if (r.reason != null) ('Alasan penolakan', r.reason!),
            ]),
          ]),
          right: AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Perkembangan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 12),
              for (final s in steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            s.$2
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: s.$1 == 'Ditolak'
                                ? AppColors.danger
                                : (s.$2 ? AppColors.success : AppColors.border),
                            size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.$1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                if (s.$3 != null)
                                  Text(s.$3!,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary)),
                              ]),
                        ),
                      ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
