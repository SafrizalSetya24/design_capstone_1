import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasInventoryDetailPage extends StatelessWidget {
  final UnitItem item;

  const SaprasInventoryDetailPage({super.key, required this.item});

  void _showAddUnitDialog(BuildContext context, InventoryStore inv) {
    final codeCtrl = TextEditingController(text: '${item.id.toUpperCase()}-${(item.total + 1).toString().padLeft(3, '0')}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Barcode Unit Fisik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Kode Barcode Unit Fisik'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (codeCtrl.text.isNotEmpty) {
                inv.addUnit(item, codeCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unit fisik berhasil didaftarkan.')),
                );
              }
            },
            child: const Text('Tambah Unit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final liveItem = inv.itemById(item.id) ?? item;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveItem.name),
        actions: [
          IconButton(
            tooltip: 'Tambah Unit Fisik Baru',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddUnitDialog(context, inv),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ringkasan Model
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: ItemIcon(name: liveItem.iconKey, size: 32, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(liveItem.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('${liveItem.category} • Lokasi: ${liveItem.location}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(
                                'Total: ${liveItem.total} unit • Tersedia: ${liveItem.available} unit',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Unit Fisik & Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Tambah Unit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () => _showAddUnitDialog(context, inv),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveItem.units.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final u = liveItem.units[idx];
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  Text(
                                    'Kondisi: ${u.condition.label}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: u.condition == ItemCondition.layak ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.status == UnitStatus.tersedia
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                u.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: u.status == UnitStatus.tersedia ? Colors.blue.shade800 : Colors.purple.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
