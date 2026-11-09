import 'package:flutter/material.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/pages/history/borrowing_detail_history_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class BorrowingSuccessPage extends StatelessWidget {
  final LoanRequest request;

  const BorrowingSuccessPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Alur SOP Selesai (Langkah 6)
                    const BorrowingFlowStepper(
                      currentStep: 6,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pengajuan Berhasil Dikirim!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifikasi wajah Anda telah terkonfirmasi secara biometrik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Detail Ringkas Request
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nomor Request:', style: TextStyle(fontSize: 12)),
                              Text(
                                request.id,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status Saat Ini:', style: TextStyle(fontSize: 12)),
                              StatusBadge.status( request.status),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Batas Keputusan Sapras:', style: TextStyle(fontSize: 12)),
                              CountdownBadge(deadline: request.expiresAt),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sesuai ketentuan (SLA 2 Jam), petugas Sapras akan menyetujui atau menolak peminjaman ini. Jika dalam 2 jam belum dikonfirmasi, booking akan kedaluwarsa secara otomatis.',
                              style: TextStyle(fontSize: 11.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: 'Lihat Detail & Status Peminjaman',
                      icon: Icons.receipt_long,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => BorrowingDetailHistoryPage(request: request),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                      child: const Center(child: Text('Kembali ke Beranda')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
