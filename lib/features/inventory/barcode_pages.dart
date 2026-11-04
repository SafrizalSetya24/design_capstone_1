import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/unit_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class BarcodePreviewPage extends StatelessWidget {
  final String itemId;
  const BarcodePreviewPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final it = context.watch<InventoryStore>().itemById(itemId);
    if (it == null) {
      return const AppPage(title: 'Barcode Unit', body: EmptyState(icon: Icons.qr_code_2, title: 'Barang tidak ditemukan', message: ''));
    }
    return AppPage(
      title: 'Barcode Unit',
      body: PageList(children: [
        AppCard(
          child: Row(children: [
            ItemImage(iconKey: it.iconKey, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('${it.total} unit - ${it.location}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
            onPressed: () => push(context, LabelPrintPage(itemId: itemId)),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Cetak label barcode'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
            onPressed: () => simulateExport(context, 'label_${it.units.isEmpty ? 'unit' : it.units.first.code.split('-').first}.pdf'),
            icon: const Icon(Icons.save_alt),
            label: const Text('Simpan label (PDF)'),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        ResponsiveGrid(minItemWidth: 260, children: [
          for (final u in it.units)
            AppCard(
              onTap: () => push(context, UnitDetailPage(code: u.code)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                BarcodeView(code: u.code, height: 56),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: StatusBadge.fromStatus(u.condition.label)),
                  const SizedBox(width: 6),
                  StatusBadge.fromStatus(u.status.label),
                ]),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class LabelPrintPage extends StatefulWidget {
  final String itemId;
  const LabelPrintPage({super.key, required this.itemId});
  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> {
  String _size = 'Sedang';

  @override
  Widget build(BuildContext context) {
    final it = context.watch<InventoryStore>().itemById(widget.itemId);
    if (it == null) {
      return const AppPage(title: 'Cetak Label', body: EmptyState(icon: Icons.print_disabled_outlined, title: 'Barang tidak ditemukan', message: ''));
    }
    final w = _size == 'Kecil' ? 200.0 : (_size == 'Sedang' ? 260.0 : 320.0);
    return AppPage(
      title: 'Cetak Label Barcode',
      body: PageList(children: [
        AppCard(
          child: FormRow(children: [
            AppDropdown.strings(label: 'Ukuran label', icon: Icons.aspect_ratio, value: _size, options: const ['Kecil', 'Sedang', 'Besar'], onChanged: (v) => setState(() => _size = v ?? _size)),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => simulateExport(context, 'cetak_label_${it.name.split(' ').first.toLowerCase()}.pdf'),
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => simulateExport(context, 'label_${it.name.split(' ').first.toLowerCase()}.png'),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Simpan'),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Pratinjau ${it.total} label', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final u in it.units)
            Container(
              width: w,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                Row(children: const [
                  Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.navy),
                  SizedBox(width: 6),
                  Text('SIPINTAR', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                BarcodeView(code: u.code, height: 44),
                const SizedBox(height: 4),
                Text(it.location, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
        ]),
      ]),
    );
  }
}
