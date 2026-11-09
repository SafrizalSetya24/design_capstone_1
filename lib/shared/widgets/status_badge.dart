import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/user_model.dart';

enum BadgeTone { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StatusBadge(this.label, {super.key, required this.tone});

  StatusBadge.status(dynamic status, {super.key})
      : label = _extractLabel(status),
        tone = toneOf(_extractLabel(status));

  static String extractLabel(dynamic status) => _extractLabel(status);

  static String _extractLabel(dynamic status) {
    if (status == null) return '';
    if (status is String) return status;
    if (status is LoanStatus) {
      return switch (status) {
        LoanStatus.menungguVerifikasiWajah => 'Menunggu verifikasi wajah',
        LoanStatus.verifikasiBerhasil => 'Verifikasi berhasil',
        LoanStatus.menungguPersetujuan => 'Menunggu persetujuan Sapras',
        LoanStatus.disetujui => 'Disetujui',
        LoanStatus.ditolak => 'Ditolak',
        LoanStatus.kedaluwarsa => 'Booking expired (2 jam)',
        LoanStatus.sedangDipinjam => 'Sedang dipinjam',
        LoanStatus.menungguPengembalian => 'Menunggu pengembalian',
        LoanStatus.selesai => 'Selesai / Dikembalikan',
      };
    }
    if (status is ConsumableStatus) {
      return switch (status) {
        ConsumableStatus.menunggu => 'Menunggu persetujuan',
        ConsumableStatus.disetujui => 'Disetujui, menunggu penyerahan',
        ConsumableStatus.ditolak => 'Ditolak',
        ConsumableStatus.diserahkan => 'Sudah diserahkan',
      };
    }
    if (status is ItemCondition) {
      return switch (status) {
        ItemCondition.layak => 'Layak pakai',
        ItemCondition.perluDiperbaiki => 'Perlu diperbaiki',
        ItemCondition.rusakTotal => 'Rusak total',
      };
    }
    if (status is UnitStatus) {
      return switch (status) {
        UnitStatus.tersedia => 'Tersedia',
        UnitStatus.dipinjam => 'Sedang dipinjam',
        UnitStatus.perbaikan => 'Dalam perbaikan',
        UnitStatus.nonaktif => 'Tidak aktif',
      };
    }
    if (status is RepairStatus) {
      return switch (status) {
        RepairStatus.menunggu => 'Menunggu perbaikan',
        RepairStatus.diperbaiki => 'Sedang diperbaiki',
        RepairStatus.selesai => 'Selesai diperbaiki',
        RepairStatus.tidakDapatDiperbaiki => 'Tidak dapat diperbaiki',
      };
    }
    if (status is CategoryType) {
      return switch (status) {
        CategoryType.perUnit => 'Barang Per Unit',
        CategoryType.habisPakai => 'Barang Habis Pakai',
      };
    }
    if (status is UserRole) {
      return switch (status) {
        UserRole.siswa => 'Siswa',
        UserRole.guru => 'Guru',
        UserRole.sapras => 'Petugas Sapras',
        UserRole.admin => 'Admin',
      };
    }
    try {
      final dynamic l = (status as dynamic).label;
      if (l != null) return l.toString();
    } catch (_) {}
    return '$status';
  }

  factory StatusBadge.fromStatus(String status) =>
      StatusBadge(status, tone: toneOf(status));

  static BadgeTone toneOf(String status) {
    final s = status.toLowerCase();
    if (s.contains('nonaktif') || s.contains('tidak aktif')) {
      return BadgeTone.neutral;
    }
    if (s.contains('tidak dapat') ||
        s.contains('ditolak') ||
        s.contains('rusak') ||
        s.contains('kedaluwarsa') ||
        s.contains('expired')) {
      return BadgeTone.danger;
    }
    if (s.contains('selesai') ||
        s.contains('layak') ||
        s.contains('berhasil') ||
        s.contains('disetujui') ||
        s.contains('dikembalikan') ||
        s.contains('diserahkan') ||
        s.contains('tersedia') ||
        s.contains('aktif')) {
      return BadgeTone.success;
    }
    if (s.contains('menunggu') ||
        s.contains('perlu') ||
        s.contains('menipis')) {
      return BadgeTone.warning;
    }
    if (s.contains('dipinjam') ||
        s.contains('diperbaiki') ||
        s.contains('perbaikan')) {
      return BadgeTone.info;
    }
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
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
