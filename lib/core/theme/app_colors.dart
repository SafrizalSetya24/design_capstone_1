import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const navy = Color(0xFF0B2A5B);
  static const blue = Color(0xFF1F6FEB);
  static const primary = navy;
  static const primaryLight = blue;
  static const background = Color(0xFFF3F6FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF14213D);
  static const textSecondary = Color(0xFF64748B);

  // Status
  static const success = Color(0xFF16A34A); // berhasil / layak pakai
  static const warning = Color(0xFFF97316); // menunggu persetujuan
  static const danger = Color(0xFFDC2626); // rusak / ditolak
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 16.0;
}
