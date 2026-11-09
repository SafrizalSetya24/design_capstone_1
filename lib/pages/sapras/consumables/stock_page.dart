import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasStockPage extends StatelessWidget {
  const SaprasStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cons = context.watch<ConsumableStore>();
    final movements = cons.movements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Mutasi Stok (Stock Movement)'),
      ),
      body: SafeArea(
        child: movements.isEmpty
            ? const Center(child: Text('Belum ada catatan mutasi stok.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: movements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final m = movements[idx];
                  final isMasuk = m.isIn;

                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMasuk ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isMasuk ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text('${m.note} • Oleh: ${m.actor}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(Format.dateTime(m.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          '${isMasuk ? "+" : "-"}${m.qty}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isMasuk ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
