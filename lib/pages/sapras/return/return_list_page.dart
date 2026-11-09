import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/return/return_inspection_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasReturnListPage extends StatelessWidget {
  const SaprasReturnListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanStore>();

    // Hanya request yang sedang dipinjam (dan memiliki barang per unit)
    final activeLoans = loans
        .withStatus({LoanStatus.sedangDipinjam, LoanStatus.menungguPengembalian})
        .where((l) => l.unitCodes.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Barang Per Unit'),
      ),
      body: activeLoans.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada barang yang sedang dipinjam',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semua barang inventaris per unit sudah kembali ke gudang.',
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activeLoans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final req = activeLoans[idx];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          StatusBadge.status( req.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peminjam: ${req.borrower.name} (${req.borrower.identityValue})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text('Barang: ${req.summary}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: req.unitCodes.map((c) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(c, style: const TextStyle(fontSize: 11)),
                          avatar: const Icon(Icons.qr_code, size: 14),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.fact_check_outlined, size: 16),
                            label: const Text('Inspeksi & Terima Pengembalian'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ReturnInspectionPage(request: req)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
