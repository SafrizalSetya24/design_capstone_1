import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/inventory/inventory_detail_page.dart';
import 'package:sipintar/pages/sapras/inventory/inventory_form_page.dart';

class SaprasInventoryListPage extends StatefulWidget {
  const SaprasInventoryListPage({super.key});

  @override
  State<SaprasInventoryListPage> createState() => _SaprasInventoryListPageState();
}

class _SaprasInventoryListPageState extends State<SaprasInventoryListPage> {
  String _search = '';
  String _filterStatus = 'Semua';

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();

    // Flatten all physical units for the detailed Sapras table (Section 30)
    final allUnits = <({UnitItem item, AssetUnit unit})>[];
    for (final it in inv.items) {
      for (final u in it.units) {
        final matchSearch = u.code.toLowerCase().contains(_search) ||
            it.name.toLowerCase().contains(_search) ||
            it.category.toLowerCase().contains(_search);
        final matchStatus = _filterStatus == 'Semua' || u.status.label == _filterStatus;
        if (matchSearch && matchStatus) {
          allUnits.add((item: it, unit: u));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris Barang Per Unit'),
        actions: [
          IconButton(
            tooltip: 'Tambah Model Barang Baru',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SaprasInventoryFormPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
          children: [
            // Search & Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari kode barcode (LPT-001) atau nama model...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                            : null,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                      DropdownMenuItem(value: 'Tersedia', child: Text('Tersedia')),
                      DropdownMenuItem(value: 'Sedang dipinjam', child: Text('Dipinjam')),
                      DropdownMenuItem(value: 'Dalam perbaikan', child: Text('Perbaikan')),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v ?? 'Semua'),
                  ),
                ],
              ),
            ),

            // Tabel unit inventaris barang
            Expanded(
              child: allUnits.isEmpty
                  ? const Center(child: Text('Tidak ada unit barang yang cocok.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Model Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Kondisi', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Lokasi', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: allUnits.map((pair) {
                              final it = pair.item;
                              final u = pair.unit;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(u.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(it.name)),
                                  DataCell(Text(it.category)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: u.condition == ItemCondition.layak
                                            ? Colors.green.withValues(alpha: 0.12)
                                            : Colors.orange.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        u.condition.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: u.condition == ItemCondition.layak ? Colors.green.shade800 : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: u.status == UnitStatus.tersedia
                                            ? Colors.blue.withValues(alpha: 0.12)
                                            : u.status == UnitStatus.dipinjam
                                                ? Colors.purple.withValues(alpha: 0.12)
                                                : Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        u.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: u.status == UnitStatus.tersedia
                                              ? Colors.blue.shade800
                                              : u.status == UnitStatus.dipinjam
                                                  ? Colors.purple.shade800
                                                  : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(it.location)),
                                  DataCell(
                                    TextButton(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => SaprasInventoryDetailPage(item: it)),
                                      ),
                                      child: const Text('Detail'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}
