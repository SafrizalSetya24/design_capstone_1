import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasManualUnitSelectionPage extends StatefulWidget {
  final String itemId;
  final String itemName;
  final int requiredQty;
  final List<String> currentSelected;

  const SaprasManualUnitSelectionPage({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.requiredQty,
    required this.currentSelected,
  });

  @override
  State<SaprasManualUnitSelectionPage> createState() => _SaprasManualUnitSelectionPageState();
}

class _SaprasManualUnitSelectionPageState extends State<SaprasManualUnitSelectionPage> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentSelected);
  }

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else {
        if (_selected.length < widget.requiredQty) {
          _selected.add(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maksimal ${widget.requiredQty} unit sesuai jumlah yang diminta.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final it = inv.itemById(widget.itemId);

    final validUnits = it?.units.where((u) => u.borrowable).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Unit Manual: ${widget.itemName}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Dibutuhkan: ${widget.requiredQty} unit', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selected.length == widget.requiredQty ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Terpilih: ${_selected.length} / ${widget.requiredQty}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: validUnits.isEmpty
                  ? const Center(child: Text('Tidak ada unit fisik yang memenuhi syarat (Layak Pakai & Tersedia).'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: validUnits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final u = validUnits[idx];
                        final isChecked = _selected.contains(u.code);

                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isChecked,
                            onChanged: (_) => _toggle(u.code),
                            title: Text(u.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              'Kondisi: ${u.condition.label} • Status: ${u.status.label}',
                              style: const TextStyle(fontSize: 12, color: Colors.green),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code, size: 20, color: AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Konfirmasi Pilihan Unit (${_selected.length}/${widget.requiredQty})',
                icon: Icons.check,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
