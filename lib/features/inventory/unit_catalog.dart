import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_form_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class UnitCatalogView extends StatefulWidget {
  const UnitCatalogView({super.key});
  @override
  State<UnitCatalogView> createState() => _UnitCatalogViewState();
}

class _UnitCatalogViewState extends State<UnitCatalogView> {
  String _q = '';
  String _cat = 'Semua';
  String _cond = 'Semua';
  String _avail = 'Semua';

  int get _active => [_cat, _cond, _avail].where((e) => e != 'Semua').length;

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final list = inv.items.where((i) {
      if (_q.isNotEmpty && !i.name.toLowerCase().contains(_q.toLowerCase()) && !i.category.toLowerCase().contains(_q.toLowerCase())) return false;
      if (_cat != 'Semua' && i.category != _cat) return false;
      if (_cond != 'Semua' && !i.hasCond(ItemCondition.values.firstWhere((c) => c.label == _cond))) return false;
      if (_avail == 'Tersedia' && i.available == 0) return false;
      if (_avail == 'Tidak tersedia' && i.available > 0) return false;
      return true;
    }).toList();

    return SimLoading(
      child: PageList(children: [
        SearchField(hint: 'Cari laptop, proyektor, kamera...', onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            initiallyExpanded: MediaQuery.of(context).size.width >= 900,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.tune),
            title: Text(_active == 0 ? 'Filter' : 'Filter ($_active aktif)', style: const TextStyle(fontWeight: FontWeight.w700)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterRow(label: 'Kategori', options: ['Semua', ...inv.categoryNames(CategoryType.perUnit)], selected: _cat, onSelected: (v) => setState(() => _cat = v)),
              FilterRow(label: 'Kondisi', options: ['Semua', ...ItemCondition.values.map((c) => c.label)], selected: _cond, onSelected: (v) => setState(() => _cond = v)),
              FilterRow(label: 'Ketersediaan', options: const ['Semua', 'Tersedia', 'Tidak tersedia'], selected: _avail, onSelected: (v) => setState(() => _avail = v)),
              if (_active > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                      onPressed: () => setState(() {
                            _cat = 'Semua';
                            _cond = 'Semua';
                            _avail = 'Semua';
                          }),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset filter')),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          const SizedBox(height: 260, child: EmptyState(icon: Icons.search_off, title: 'Barang tidak ditemukan', message: 'Ubah kata kunci atau filter pencarian Anda.'))
        else
          ResponsiveGrid(minItemWidth: 330, children: [for (final i in list) UnitCard(item: i)]),
      ]),
    );
  }
}

class UnitCard extends StatelessWidget {
  final UnitItem item;
  const UnitCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    final allGood = item.countCond(ItemCondition.layak) == item.total;
    return AppCard(
      onTap: () => push(context, ItemDetailPage(itemId: item.id)),
      child: Row(children: [
        ItemImage(iconKey: item.iconKey, size: 88),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(item.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusBadge(item.available > 0 ? '${item.available} unit tersedia' : 'Tidak tersedia',
                  tone: item.available > 0 ? BadgeTone.success : BadgeTone.danger),
              StatusBadge(item.conditionSummary, tone: allGood ? BadgeTone.success : BadgeTone.warning),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final String itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final item = context.watch<InventoryStore>().itemById(itemId);
    if (item == null) {
      return const AppPage(title: 'Detail Barang', body: EmptyState(icon: Icons.inventory_2_outlined, title: 'Barang tidak ditemukan', message: 'Barang mungkin sudah dihapus.'));
    }
    final first = item.units.isNotEmpty ? item.units.first : null;
    return AppPage(
      title: 'Detail Barang',
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ItemImage(iconKey: item.iconKey, size: 200, height: 220),
            const SizedBox(height: AppSpacing.md),
            if (first != null) ...[
              const Text('Barcode unit (contoh)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              BarcodeView(code: first.code),
              const SizedBox(height: 4),
              const Text('Barcode simulasi. Setiap unit memiliki kode aset unik.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ]),
          right: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(item.category, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(item.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Informasi barang', rows: [
              ('Ketersediaan', '${item.available} dari ${item.total} unit tersedia'),
              ('Kondisi', item.conditionSummary),
              ('Lokasi', item.location),
              ('Kode aset', item.units.isEmpty ? '-' : '${item.units.first.code.split('-').first}-* (${item.total} unit)'),
            ]),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Daftar kode aset', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final u in item.units)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(u.code, style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                      StatusBadge.fromStatus(u.condition.label),
                      const SizedBox(width: 6),
                      StatusBadge.fromStatus(u.status.label),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: item.available > 0 ? 'Ajukan peminjaman' : 'Tidak ada unit tersedia',
              icon: Icons.event_available,
              onPressed: item.available > 0 ? () => push(context, LoanFormPage(presetItemId: item.id)) : null,
            ),
          ]),
        ),
      ]),
    );
  }
}
