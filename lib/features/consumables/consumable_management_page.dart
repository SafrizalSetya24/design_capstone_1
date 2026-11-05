import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/inventory_form_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ConsumableManagementPage extends StatefulWidget {
  const ConsumableManagementPage({super.key});
  @override
  State<ConsumableManagementPage> createState() =>
      _ConsumableManagementPageState();
}

class _ConsumableManagementPageState extends State<ConsumableManagementPage> {
  String _q = '';
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final cats =
        context.watch<InventoryStore>().categoryNames(CategoryType.habisPakai);
    final list = store.items
        .where((i) =>
            (_q.isEmpty || i.name.toLowerCase().contains(_q.toLowerCase())) &&
            (_cat == 'Semua' || i.category == _cat))
        .toList();
    final low = store.lowStock;
    return AppPage(
      title: 'Barang Habis Pakai',
      actions: [
        IconButton(
            tooltip: 'Riwayat perubahan stok',
            icon: const Icon(Icons.history),
            onPressed: () => push(context, const StockHistoryPage()))
      ],
      fab: FloatingActionButton.extended(
        onPressed: () =>
            push(context, const InventoryFormPage(startUnit: false)),
        icon: const Icon(Icons.add),
        label: const Text('Tambah barang'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SimLoading(
        child: PageList(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (low.isNotEmpty) ...[
                AppCard(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text('Peringatan: ${low.length} barang stok menipis',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          for (final i in low)
                            Chip(
                                label: Text(
                                    '${i.name}: ${i.stock}/${i.minStock} ${i.satuan}'),
                                visualDensity: VisualDensity.compact)
                        ]),
                      ]),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchField(
                          hint: 'Cari barang habis pakai...',
                          onChanged: (v) => setState(() => _q = v)),
                      FilterRow(
                          label: 'Kategori',
                          options: ['Semua', ...cats],
                          selected: _cat,
                          onSelected: (v) => setState(() => _cat = v)),
                    ]),
              ),
              const SizedBox(height: AppSpacing.md),
              ResponsiveTable(
                emptyText: 'Tidak ada barang yang cocok.',
                columns: const [
                  'Barang',
                  'Kategori',
                  'Stok tersedia',
                  'Stok minimum',
                  'Status',
                  'Aksi'
                ],
                onRowTap: (i) => push(
                    context, ConsumableStaffDetailPage(itemId: list[i].id)),
                rows: [
                  for (final i in list)
                    [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        ItemImage(iconKey: i.iconKey, size: 36),
                        const SizedBox(width: 10),
                        Flexible(
                            child: Text(i.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)))
                      ]),
                      cellText(i.category),
                      cellText('${i.stock} ${i.satuan}', bold: true),
                      cellText('${i.minStock} ${i.satuan}'),
                      StatusBadge(i.low ? 'Stok menipis' : 'Stok aman',
                          tone: i.low ? BadgeTone.warning : BadgeTone.success),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            tooltip: 'Barang masuk',
                            icon: const Icon(Icons.add_box_outlined,
                                color: AppColors.success),
                            onPressed: () => push(
                                context,
                                StockMovementFormPage(
                                    itemId: i.id, isIn: true))),
                        IconButton(
                            tooltip: 'Barang keluar',
                            icon: const Icon(
                                Icons.indeterminate_check_box_outlined,
                                color: AppColors.danger),
                            onPressed: () => push(
                                context,
                                StockMovementFormPage(
                                    itemId: i.id, isIn: false))),
                      ]),
                    ],
                ],
              ),
            ]),
      ),
    );
  }
}

class ConsumableStaffDetailPage extends StatelessWidget {
  final String itemId;
  const ConsumableStaffDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final i = store.itemById(itemId);
    if (i == null) {
      return const AppPage(
          title: 'Detail Stok',
          body: EmptyState(
              icon: Icons.layers_outlined,
              title: 'Barang tidak ditemukan',
              message: 'Barang mungkin sudah dihapus.'));
    }
    final moves = store.movements.where((m) => m.itemId == i.id).toList();
    return AppPage(
      title: 'Detail Stok',
      actions: [
        IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => push(context, InventoryFormPage(cons: i)))
      ],
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ItemImage(iconKey: i.iconKey, size: 180, height: 180),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
                title: i.name,
                trailing: StatusBadge(i.low ? 'Stok menipis' : 'Stok aman',
                    tone: i.low ? BadgeTone.warning : BadgeTone.success),
                rows: [
                  ('Kategori', i.category),
                  ('Stok tersedia', '${i.stock} ${i.satuan}'),
                  ('Stok minimum', '${i.minStock} ${i.satuan}'),
                  ('Lokasi', i.location),
                ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: () => push(context,
                          StockMovementFormPage(itemId: i.id, isIn: true)),
                      icon: const Icon(Icons.add),
                      label: const Text('Masuk'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => push(context,
                          StockMovementFormPage(itemId: i.id, isIn: false)),
                      icon: const Icon(Icons.remove),
                      label: const Text('Keluar'))),
            ]),
          ]),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(i.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Riwayat perubahan stok'),
            const SizedBox(height: 8),
            if (moves.isEmpty)
              const AppCard(
                  child: Text('Belum ada perubahan stok.',
                      style: TextStyle(color: AppColors.textSecondary)))
            else
              for (final m in moves)
                RowCard(
                  leading: CircleAvatar(
                      backgroundColor:
                          (m.isIn ? AppColors.success : AppColors.danger)
                              .withValues(alpha: 0.12),
                      child: Icon(m.isIn ? Icons.south_west : Icons.north_east,
                          color: m.isIn ? AppColors.success : AppColors.danger,
                          size: 18)),
                  title: '${m.isIn ? '+' : '-'}${m.qty} ${i.satuan}',
                  subtitle: '${Fmt.dateTime(m.date)} - ${m.actor}',
                  extra: [Text(m.note, style: const TextStyle(fontSize: 13))],
                ),
          ]),
        ),
      ]),
    );
  }
}

class StockMovementFormPage extends StatefulWidget {
  final String? itemId;
  final bool isIn;
  const StockMovementFormPage({super.key, this.itemId, required this.isIn});
  @override
  State<StockMovementFormPage> createState() => _StockMovementFormPageState();
}

class _StockMovementFormPageState extends State<StockMovementFormPage> {
  final _form = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  late String? _id = widget.itemId;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<ConsumableStore>();
    final item = store.itemById(_id!)!;
    final q = int.parse(_qty.text);
    if (widget.isIn) {
      store.addStock(item, q, _note.text.trim());
    } else {
      final err = store.removeStock(item, q, _note.text.trim());
      if (err != null) {
        snack(context, err, error: true);
        return;
      }
    }
    snack(context, 'Stok ${item.name} diperbarui.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final cur = _id == null ? null : store.itemById(_id!);
    return FormScaffold(
      title: widget.isIn ? 'Barang Masuk' : 'Barang Keluar',
      formKey: _form,
      submitLabel: widget.isIn ? 'Tambah stok' : 'Kurangi stok',
      submitIcon: widget.isIn ? Icons.add : Icons.remove,
      onSubmit: _save,
      children: [
        AppDropdown<String>(
          label: 'Barang',
          icon: Icons.layers_outlined,
          value: _id,
          items: [
            for (final i in store.items)
              DropdownMenuItem(
                  value: i.id,
                  child: Text('${i.name} (stok ${i.stock} ${i.satuan})',
                      overflow: TextOverflow.ellipsis))
          ],
          onChanged:
              widget.itemId != null ? null : (v) => setState(() => _id = v),
          validator: (v) => v == null ? 'Pilih barang' : null,
        ),
        AppTextField(
          controller: _qty,
          label: 'Jumlah${cur == null ? '' : ' (${cur.satuan})'}',
          icon: Icons.numbers,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 1) return 'Masukkan jumlah minimal 1';
            if (!widget.isIn && cur != null && n > cur.stock) {
              return 'Melebihi stok (${cur.stock})';
            }
            return null;
          },
        ),
        AppTextField(
            controller: _note,
            label: widget.isIn ? 'Sumber / catatan' : 'Alasan / catatan',
            icon: Icons.notes,
            maxLines: 2),
      ],
    );
  }
}

class StockHistoryPage extends StatefulWidget {
  const StockHistoryPage({super.key});
  @override
  State<StockHistoryPage> createState() => _StockHistoryPageState();
}

class _StockHistoryPageState extends State<StockHistoryPage> {
  String _type = 'Semua';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsumableStore>();
    final list = store.movements.where((m) {
      if (_type == 'Masuk' && !m.isIn) return false;
      if (_type == 'Keluar' && m.isIn) return false;
      return _q.isEmpty || m.itemName.toLowerCase().contains(_q.toLowerCase());
    }).toList();
    return AppPage(
      title: 'Riwayat Perubahan Stok',
      body: PageList(children: [
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SearchField(
                hint: 'Cari barang...',
                onChanged: (v) => setState(() => _q = v)),
            FilterRow(
                label: 'Jenis perubahan',
                options: const ['Semua', 'Masuk', 'Keluar'],
                selected: _type,
                onSelected: (v) => setState(() => _type = v)),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveTable(
          emptyText: 'Tidak ada riwayat.',
          columns: const [
            'Tanggal',
            'Barang',
            'Jenis',
            'Jumlah',
            'Catatan',
            'Petugas'
          ],
          rows: [
            for (final m in list)
              [
                cellText(Fmt.dateTime(m.date)),
                cellText(m.itemName, bold: true),
                StatusBadge(m.isIn ? 'Masuk' : 'Keluar',
                    tone: m.isIn ? BadgeTone.success : BadgeTone.danger),
                cellText('${m.isIn ? '+' : '-'}${m.qty}', bold: true),
                cellText(m.note),
                cellText(m.actor),
              ],
          ],
        ),
      ]),
    );
  }
}
