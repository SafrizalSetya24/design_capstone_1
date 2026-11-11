import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/borrowing/borrowing_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

// Halaman antrean persetujuan (approval) peminjaman sarpras dengan batas waktu SLA 2 jam
class SaprasApprovalPage extends StatelessWidget {
  const SaprasApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loanStore = context.watch<LoanStore>();
    final pendingRequests = loanStore.withStatus({LoanStatus.menungguPersetujuan});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Approval (SLA 2 Jam)'),
      ),
      body: pendingRequests.isEmpty
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
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Kartu: ID Peminjaman & Countdown Timer SLA 2 Jam
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                request.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              CountdownBadge(deadline: request.expiresAt),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Identitas Peminjam & Rangkuman Barang
                          Text(
                            '${request.borrower.name} (${request.borrower.identityValue})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            request.summary,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 4),

                          // Jadwal & Keperluan Peminjaman
                          Text(
                            'Jadwal: ${Format.range(request.start, request.end)}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          ),
                          Text(
                            'Keperluan: ${request.purpose}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 14),

                          // Tombol Aksi Membuka Detail Pengajuan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SaprasBorrowingDetailPage(request: request),
                                  ),
                                ),
                                child: const Text(
                                  'Buka & Putuskan',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
