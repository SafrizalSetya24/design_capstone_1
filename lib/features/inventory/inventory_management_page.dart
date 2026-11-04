import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/consumables/consumable_management_page.dart';
import 'package:sipintar/features/inventory/inventory_form_page.dart';
import 'package:sipintar/features/inventory/unit_item_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});
  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _Entry {
  final bool unit;
  final String id, name, category, qty, cond, avail;
  final UnitItem? u;
  final ConsumableItem? c;
  _Entry(this.unit, this.id, this.name, this.category, this.qty, this.cond, this.avail, {this.u, this.c});
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  String _q = '';
  String _type = 'Semua';
  String _cat = 'Semua';
  String _cond = 'Semua';
  String _avail = 'Semua';

  Future<void> _delete(_Entry e) async {
    final ok = await confirm(context, title: 'Hapus ${e.name}?', message: 'Data barang akan dihapus dari inventaris. Tindakan ini tidak dapat dibatalkan.', confirmLabel: 'Hapus', danger: true);
    if (!ok || !mounted) return;
    if (e.unit) {
      final err = context.read<InventoryStore>().deleteItem(e.u!);
      snack(context, err ?? '${e.name} dihapus.', error: err != null);
    } else {
      context.read<ConsumableStore>().deleteItem(e.c!);
      snack(context, '${e.name} dihapus.');
    }
  }

  void _open(_Entry e) => push(context, e.unit ? UnitItemDetailPage(itemId: e.id) : ConsumableStaffDetailPage(itemId: e.id));
  void _edit(_Entry e) => push(context, InventoryFormPage(unit: e.u, cons: e.c));

  void _add() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.laptop_mac_rounded),
            title: const Text('Barang per unit'),
            subtitle: const Text('Laptop, proyektor, kamera. Barcode dibuat per unit.'),
            onTap: () {
              Navigator.pop(sheet);
              push(context, const InventoryFormPage(startUnit: true));
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Barang habis pakai'),
            subtitle: const Text('Kertas, pulpen, tinta. Dikelola berdasarkan stok.'),
            onTap: () {
              Navigator.pop(sheet);
              push(context, const InventoryFormPage(startUnit: false));
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final all = <_Entry>[
      for (final i in inv.items)
        _Entry(true, i.id, i.name, i.category, '${i.total} unit', i.conditionSummary, i.available > 0 ? 'Tersedia' : 'Tidak tersedia', u: i),
      for (final c in cons.items)
        _Entry(false, c.id, c.name, c.category, '${c.stock} ${c.satuan}', '-', c.stock == 0 ? 'Tidak tersedia' : (c.low ? 'Stok menipis' : 'Tersedia'), c: c),
    ];
    final list = all.where((e) {
      if (_q.isNotEmpty && !e.name.toLowerCase().contains(_q.toLowerCase())) return false;
      if (_type == 'Per unit' && !e.unit) return false;
      if (_type == 'Habis pakai' && e.unit) return false;
      if (_cat != 'Semua' && e.category != _cat) return false;
      if (_cond != 'Semua') {
        if (!e.unit) return false;
        final c = ItemCondition.values.firstWhere((x) => x.label == _cond);
        if (!e.u!.hasCond(c)) return false;
      }
      if (_avail != 'Semua' && e.avail != _avail) return false;
      return true;
    }).toList();

    final List<String> cats = ['Semua', ...inv.categories.map((c) => c.name)];

    return AppPage(
      title: 'Manajemen Inventaris',
      fab: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tambah barang'), backgroundColor: AppColors.navy, foregroundColor: Colors.white),
      body: SimLoading(
        child: PageList(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SearchField(hint: 'Cari nama barang...', onChanged: (v) => setState(() => _q = v)),
              FilterRow(label: 'Jenis barang', options: const ['Semua', 'Per unit', 'Habis pakai'], selected: _type, onSelected: (v) => setState(() => _type = v)),
              FilterRow(label: 'Kategori', options: cats, selected: _cat, onSelected: (v) => setState(() => _cat = v)),
              FilterRow(label: 'Kondisi', options: ['Semua', ...ItemCondition.values.map((c) => c.label)], selected: _cond, onSelected: (v) => setState(() => _cond = v)),
              FilterRow(label: 'Ketersediaan', options: const ['Semua', 'Tersedia', 'Tidak tersedia', 'Stok menipis'], selected: _avail, onSelected: (v) => setState(() => _avail = v)),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${list.length} barang', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ResponsiveTable(
            emptyText: 'Tidak ada barang yang cocok dengan filter.',
            columns: const ['Barang', 'Jenis', 'Kategori', 'Jumlah', 'Kondisi', 'Ketersediaan', 'Aksi'],
            onRowTap: (i) => _open(list[i]),
            rows: [
              for (final e in list)
                [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ItemImage(iconKey: (e.u?.iconKey ?? e.c!.iconKey), size: 36),
                    const SizedBox(width: 10),
                    Flexible(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                  cellText(e.unit ? 'Per unit' : 'Habis pakai'),
                  cellText(e.category),
                  cellText(e.qty, bold: true),
                  e.unit ? StatusBadge(e.cond, tone: e.u!.countCond(ItemCondition.layak) == e.u!.total ? BadgeTone.success : BadgeTone.warning) : cellText('-'),
                  StatusBadge(e.avail, tone: e.avail == 'Tersedia' ? BadgeTone.success : (e.avail == 'Stok menipis' ? BadgeTone.warning : BadgeTone.danger)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _edit(e)),
                    IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _delete(e)),
                  ]),
                ],
            ],
          ),
        ]),
      ),
    );
  }
}
