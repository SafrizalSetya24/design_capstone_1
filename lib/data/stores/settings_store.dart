import 'package:flutter/foundation.dart';
import 'package:sipintar/data/models/user_model.dart';

class SettingsStore extends ChangeNotifier {
  int approvalHours = 12;
  String schoolName = 'SMK Nusantara';
  String academicYear = '2026/2027';
  int minPasswordLength = 8;
  int sessionMinutes = 30;
  bool lockoutEnabled = true;
  final Map<String, bool> prefs = {
    'persetujuan': true,
    'pengingat': true,
    'stok': true,
    'email': false,
  };

  static const permissionLabels = <String, String>{
    'pinjam_unit': 'Meminjam barang per unit',
    'minta_habis_pakai': 'Meminta barang habis pakai',
    'riwayat': 'Melihat riwayat transaksi',
    'notifikasi': 'Menerima notifikasi',
    'chatbot': 'Menggunakan AI Chatbot',
    'kelola_inventaris': 'Mengelola inventaris',
    'persetujuan': 'Menyetujui pengajuan',
    'penyerahan_pengembalian': 'Penyerahan dan pengembalian',
    'laporan': 'Melihat laporan',
    'forecasting': 'Melihat forecasting',
    'kelola_pengguna': 'Mengelola pengguna',
    'kelola_role': 'Mengelola role dan hak akses',
    'audit_log': 'Melihat audit log',
    'pengaturan_sistem': 'Mengubah pengaturan sistem',
  };

  /// Fitur yang dikunci (tidak dapat diubah) per role.
  static const Map<UserRole, Set<String>> locked = {
    UserRole.admin: {'chatbot', 'forecasting'},
  };

  final Map<UserRole, Map<String, bool>> permissions = {
    UserRole.siswa: _mk({'pinjam_unit', 'minta_habis_pakai', 'riwayat', 'notifikasi', 'chatbot'}),
    // Chatbot Guru sengaja nonaktif: mengikuti konfigurasi, tidak diasumsikan aktif.
    UserRole.guru: _mk({'pinjam_unit', 'minta_habis_pakai', 'riwayat', 'notifikasi'}),
    UserRole.sapras: _mk({'notifikasi', 'chatbot', 'kelola_inventaris', 'persetujuan', 'penyerahan_pengembalian', 'laporan', 'forecasting'}),
    UserRole.admin: _mk({'notifikasi', 'kelola_pengguna', 'kelola_role', 'audit_log', 'pengaturan_sistem'}),
  };

  static Map<String, bool> _mk(Set<String> on) => {for (final k in permissionLabels.keys) k: on.contains(k)};

  bool can(UserRole r, String key) => permissions[r]?[key] ?? false;
  bool isLocked(UserRole r, String key) => locked[r]?.contains(key) ?? false;
  int grantedCount(UserRole r) => permissions[r]!.values.where((v) => v).length;

  void setPermission(UserRole r, String key, bool v) {
    if (isLocked(r, key)) return;
    permissions[r]![key] = v;
    notifyListeners();
  }

  void setApprovalHours(int h) {
    approvalHours = h;
    notifyListeners();
  }

  void setPref(String key, bool v) {
    prefs[key] = v;
    notifyListeners();
  }

  void update({String? school, String? year, int? minPass, int? session, bool? lockout}) {
    schoolName = school ?? schoolName;
    academicYear = year ?? academicYear;
    minPasswordLength = minPass ?? minPasswordLength;
    sessionMinutes = session ?? sessionMinutes;
    lockoutEnabled = lockout ?? lockoutEnabled;
    notifyListeners();
  }
}
