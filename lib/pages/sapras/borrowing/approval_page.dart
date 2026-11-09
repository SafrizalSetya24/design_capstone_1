import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/borrowing/borrowing_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasApprovalPage extends StatelessWidget {
  const SaprasApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanStore>();
    final pending = loans.withStatus({LoanStatus.menungguPersetujuan});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Approval (SLA 2 Jam)'),
      ),
      body: pending.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'Semua pengajuan sudah diproses!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tidak ada antrean peminjaman yang menunggu persetujuan.',
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final req = pending[idx];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          CountdownBadge(deadline: req.expiresAt),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${req.borrower.name} (${req.borrower.identityValue})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(req.summary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 4),
                      Text('Jadwal: ${Format.range(req.start, req.end)}', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                      Text('Keperluan: ${req.purpose}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SaprasBorrowingDetailPage(request: req)),
                            ),
                            child: const Text('Buka & Putuskan'),
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
