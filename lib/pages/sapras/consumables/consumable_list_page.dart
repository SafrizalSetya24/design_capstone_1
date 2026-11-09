import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/consumables/stock_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasConsumableListPage extends StatelessWidget {
  const SaprasConsumableListPage({super.key});

  void _showAddStockDialog(BuildContext context, ConsumableStore cons, ConsumableItem item) {
    final qtyCtrl = TextEditingController(text: '10');
    final noteCtrl = TextEditingController(text: 'Pengadaan logistik baru');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Stok: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah Masuk (${item.satuan})'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan Pengadaan'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final q = int.tryParse(qtyCtrl.text) ?? 0;
              if (q > 0) {
                cons.addStock(item, q, noteCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stok ${item.name} berhasil ditambahkan (+$q).')),
                );
              }
            },
            child: const Text('Simpan Stok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cons = context.watch<ConsumableStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Barang Habis Pakai (ATK)'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Keluar Masuk Stok',
            icon: const Icon(Icons.history_toggle_off),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SaprasStockPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: cons.items.isEmpty
            ? const Center(child: Text('Belum ada data barang habis pakai.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cons.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = cons.items[idx];
                  final isLow = item.low;

                  return AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: ItemIcon(name: item.iconKey, size: 26, color: Colors.teal),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (isLow) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Menipis', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${item.category} • Lokasi: ${item.location}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                'Stok Tersedia: ${item.stock} ${item.satuan} (Min: ${item.minStock})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: isLow ? Colors.red : Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Tambah Stok Masuk',
                          icon: const Icon(Icons.add),
                          onPressed: () => _showAddStockDialog(context, cons, item),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.receipt_long),
        label: const Text('Riwayat Mutasi Stok'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SaprasStockPage()),
        ),
      ),
    );
  }
}
