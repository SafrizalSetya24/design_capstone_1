import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/repair/repair_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasRepairListPage extends StatefulWidget {
  const SaprasRepairListPage({super.key});

  @override
  State<SaprasRepairListPage> createState() => _SaprasRepairListPageState();
}

class _SaprasRepairListPageState extends State<SaprasRepairListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();

    final pending = inv.repairRecords.where((r) => r.status == RepairStatus.menunggu).toList();
    final inProgress = inv.repairRecords.where((r) => r.status == RepairStatus.diperbaiki).toList();
    final finished = inv.repairRecords.where((r) => r.status == RepairStatus.selesai || r.status == RepairStatus.tidakDapatDiperbaiki).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Perbaikan Barang (Repair Flow)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Menunggu (${pending.length})'),
            Tab(text: 'Sedang Diservis (${inProgress.length})'),
            Tab(text: 'Selesai (${finished.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(context, pending, 'Tidak ada unit yang menunggu perbaikan.'),
          _buildList(context, inProgress, 'Tidak ada unit yang sedang dalam proses perbaikan.'),
          _buildList(context, finished, 'Belum ada riwayat perbaikan selesai.'),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<RepairRecord> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.build_circle_outlined, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(emptyMsg, style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final r = list[idx];

        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaprasRepairDetailPage(record: r)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Unit: ${r.unitCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: r.status == RepairStatus.selesai ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: r.status == RepairStatus.selesai ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Keluhan: ${r.issue}', style: const TextStyle(fontSize: 12)),
                      Text('Teknisi: ${r.technician}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
