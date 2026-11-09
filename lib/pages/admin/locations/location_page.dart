import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminLocationPage extends StatelessWidget {
  const AdminLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final locations = inv.locations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Lokasi & Ruangan'),
      ),
      body: SafeArea(
        child: locations.isEmpty
            ? const Center(child: Text('Belum ada lokasi yang terdaftar.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final loc = locations[idx];
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.place_outlined, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text(
                                '${loc.building} • Lantai ${loc.floor}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
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
