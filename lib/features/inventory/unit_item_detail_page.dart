import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/barcode_pages.dart';
import 'package:sipintar/features/inventory/inventory_form_page.dart';
import 'package:sipintar/features/inventory/unit_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class UnitItemDetailPage extends StatelessWidget {
  final String itemId;
  const UnitItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final it = inv.itemById(itemId);
    if (it == null) {
      return const AppPage(
          title: 'Detail Inventaris',
          body: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Barang tidak ditemukan',
              message: 'Barang mungkin sudah dihapus.'));
    }
    return AppPage(
      title: 'Detail Inventaris',
      actions: [
        IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => push(context, InventoryFormPage(unit: it))),
        IconButton(
          tooltip: 'Hapus',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await confirm(context,
                title: 'Hapus ${it.name}?',
                message: 'Seluruh unit akan dihapus dari inventaris.',
                confirmLabel: 'Hapus',
                danger: true);
            if (!ok || !context.mounted) return;
            final err = inv.deleteItem(it);
            if (err != null) {
              snack(context, err, error: true);
            } else {
              snack(context, '${it.name} dihapus.');
              Navigator.of(context).pop();
            }
          },
        ),
      ],
      body: PageList(children: [
        TwoPane(
          leftFlex: 2,
          rightFlex: 3,
          left:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ItemImage(iconKey: it.iconKey, size: 200, height: 200),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: it.name, rows: [
              ('Kategori', it.category),
              ('Lokasi', it.location),
              ('Total unit', '${it.total}'),
              ('Tersedia', '${it.available}'),
              ('Layak pakai', '${it.countCond(ItemCondition.layak)}'),
              (
                'Perlu diperbaiki',
                '${it.countCond(ItemCondition.perluDiperbaiki)}'
              ),
              ('Rusak total', '${it.countCond(ItemCondition.rusakTotal)}'),
            ]),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
                onPressed: () =>
                    push(context, BarcodePreviewPage(itemId: it.id)),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Barcode dan label')),
          ]),
          right:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(it.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Daftar unit'),
            const SizedBox(height: 8),
            ResponsiveTable(
              columns: const ['Kode unit', 'Kondisi', 'Status'],
              onRowTap: (i) =>
                  push(context, UnitDetailPage(code: it.units[i].code)),
              rows: [
                for (final u in it.units)
                  [
                    cellText(u.code, bold: true),
                    StatusBadge.fromStatus(u.condition.label),
                    StatusBadge.fromStatus(u.status.label)
                  ],
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}
