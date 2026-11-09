import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminItemTypePage extends StatelessWidget {
  const AdminItemTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();

    final perUnitModels = inv.items;
    final consumableModels = cons.items;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Data Model Barang'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Model Per Unit'),
              Tab(text: 'Model Habis Pakai'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Per Unit Models
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: perUnitModels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final m = perUnitModels[idx];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ItemIcon(name: m.iconKey, size: 24, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text('${m.category} • Total Terdaftar: ${m.total} unit', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                            Text('Lokasi Standar: ${m.location}', style: const TextStyle(fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Consumable Models
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: consumableModels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final m = consumableModels[idx];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ItemIcon(name: m.iconKey, size: 24, color: Colors.teal),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text('${m.category} • Satuan: ${m.satuan}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                            Text('Stok Gudang: ${m.stock} ${m.satuan}', style: const TextStyle(fontSize: 11.5)),
                          ],
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
    );
  }
}
