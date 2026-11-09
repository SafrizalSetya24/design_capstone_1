import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

class BorrowingFlowStepper extends StatelessWidget {
  final int currentStep;
  final bool showRuleNotice;

  const BorrowingFlowStepper({
    super.key,
    required this.currentStep,
    this.showRuleNotice = false,
  });

  static const List<({String title, IconData icon})> steps = [
    (title: 'Pilih Barang', icon: Icons.search_rounded),
    (title: 'Tentukan Jumlah', icon: Icons.tune_rounded),
    (title: 'Keranjang Pengajuan', icon: Icons.shopping_cart_outlined),
    (title: 'Review & Waktu Peminjaman', icon: Icons.calendar_month_outlined),
    (title: 'Verifikasi Wajah (Biometrik)', icon: Icons.face_retouching_natural),
    (title: 'Pengajuan Selesai (Pending Sapras)', icon: Icons.send_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = currentStep.clamp(1, 6);
    final currentInfo = steps[active - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LANGKAH $active DARI 6',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(currentInfo.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  currentInfo.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stepper bar indicators (6 bars)
          Row(
            children: [
              for (int i = 1; i <= 6; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= active
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          if (showRuleNotice) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: Pemohon memilih model & kuantitas. Unit fisik spesifik ditentukan oleh petugas Sapras saat serah terima.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

