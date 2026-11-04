import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

enum BadgeTone { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  const StatusBadge(this.label, {super.key, required this.tone});

  factory StatusBadge.fromStatus(String status) => StatusBadge(status, tone: toneOf(status));

  static BadgeTone toneOf(String status) {
    final s = status.toLowerCase();
    if (s.contains('nonaktif') || s.contains('tidak aktif')) return BadgeTone.neutral;
    if (s.contains('tidak dapat') || s.contains('ditolak') || s.contains('rusak') || s.contains('kedaluwarsa')) {
      return BadgeTone.danger;
    }
    if (s.contains('selesai') || s.contains('layak') || s.contains('berhasil') || s.contains('disetujui') ||
        s.contains('dikembalikan') || s.contains('diserahkan') || s.contains('tersedia') || s.contains('aktif')) {
      return BadgeTone.success;
    }
    if (s.contains('menunggu') || s.contains('perlu') || s.contains('menipis')) return BadgeTone.warning;
    if (s.contains('dipinjam') || s.contains('diperbaiki') || s.contains('perbaikan')) return BadgeTone.info;
    return BadgeTone.neutral;
  }

  static Color colorOf(BadgeTone t) => switch (t) {
        BadgeTone.success => AppColors.success,
        BadgeTone.warning => AppColors.warning,
        BadgeTone.danger => AppColors.danger,
        BadgeTone.info => AppColors.blue,
        BadgeTone.neutral => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final c = colorOf(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
