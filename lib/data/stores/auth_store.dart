import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/data/stores/audit_store.dart';

class AuthStore extends ChangeNotifier {
  AuthStore(this._audit);
  final AuditStore _audit;
  final List<Account> accounts = DummyData.accounts();
  AppUser? currentUser;
  int _seq = 100;

  Account? _byEmail(String e) {
    for (final a in accounts) {
      if (a.user.email.toLowerCase() == e.trim().toLowerCase()) return a;
    }
    return null;
  }

  Account? accountOf(String id) {
    for (final a in accounts) {
      if (a.user.id == id) return a;
    }
    return null;
  }

  bool emailExists(String email) => _byEmail(email) != null;

  void _log(String type, String detail) {
    final u = currentUser;
    if (u != null) _audit.log(u.name, u.role.label, type, detail);
  }

  String? login(String email, String pass) {
    final a = _byEmail(email);
    if (a == null || a.password != pass) return 'Email atau kata sandi tidak sesuai. Periksa kembali lalu coba lagi.';
    if (!a.active) return 'Akun Anda dinonaktifkan. Hubungi Admin sekolah untuk mengaktifkannya kembali.';
    if (!a.emailVerified) return 'Email belum diverifikasi. Selesaikan verifikasi email terlebih dahulu.';
    a.lastLogin = DateTime.now();
    currentUser = a.user;
    _log('Login', 'Masuk ke aplikasi');
    notifyListeners();
    return null;
  }

  void logout() {
    _log('Logout', 'Keluar dari aplikasi');
    currentUser = null;
    notifyListeners();
  }

  AppUser _build(UserRole role, String id, String name, String email, String identity, String extra) => switch (role) {
        UserRole.siswa => Siswa(id: id, name: name, email: email, nis: identity, kelas: extra),
        UserRole.guru => Guru(id: id, name: name, email: email, nik: identity, mataPelajaran: extra),
        UserRole.sapras => SaprasUser(id: id, name: name, email: email, idPegawai: identity),
        UserRole.admin => AdminUser(id: id, name: name, email: email, idPegawai: identity),
      };

  String? _duplicate(UserRole role, String email, String identity, {String? exceptId}) {
    for (final a in accounts) {
      if (a.user.id == exceptId) continue;
      if (a.user.email.toLowerCase() == email.trim().toLowerCase()) return 'Email sudah terdaftar.';
      if (a.user.role == role && a.user.identityValue == identity) {
        return '${a.user.identityLabel} sudah terdaftar.';
      }
    }
    return null;
  }

  /// Registrasi mandiri Siswa/Guru. Email harus diverifikasi sebelum login.
  String? register({
    required UserRole role,
    required String name,
    required String email,
    required String identity,
    required String extra,
    required String password,
  }) {
    final dup = _duplicate(role, email, identity);
    if (dup != null) return dup;
    final id = '${role == UserRole.siswa ? 'sw' : 'gr'}${_seq++}';
    accounts.add(Account(
      user: _build(role, id, name.trim(), email.trim(), identity, extra.trim()),
      password: password,
      created: DateTime.now(),
      emailVerified: false,
    ));
    _audit.log(name.trim(), role.label, 'Registrasi', 'Membuat akun ${role.label}');
    notifyListeners();
    return null;
  }

  void verifyEmail(String email) {
    _byEmail(email)?.emailVerified = true;
    notifyListeners();
  }

  bool resetPassword(String email, String newPass) {
    final a = _byEmail(email);
    if (a == null) return false;
    a.password = newPass;
    notifyListeners();
    return true;
  }

  String? changePassword(String oldPass, String newPass) {
    final a = accountOf(currentUser!.id)!;
    if (a.password != oldPass) return 'Kata sandi lama tidak sesuai.';
    a.password = newPass;
    _log('Akun', 'Mengubah kata sandi');
    notifyListeners();
    return null;
  }

  String? updateProfile({required String name, required String email, String? extra}) {
    final me = currentUser!;
    final dup = _duplicate(me.role, email, me.identityValue, exceptId: me.id);
    if (dup != null && dup.startsWith('Email')) return dup;
    final updated = me.withProfile(name: name.trim(), email: email.trim(), extra: extra?.trim());
    accountOf(me.id)!.user = updated;
    currentUser = updated;
    _log('Akun', 'Memperbarui profil');
    notifyListeners();
    return null;
  }

  // ---- Admin ----
  int countRole(UserRole r) => accounts.where((a) => a.user.role == r).length;

  String? addUser({
    required UserRole role,
    required String name,
    required String email,
    required String identity,
    required String extra,
    required String password,
  }) {
    final dup = _duplicate(role, email, identity);
    if (dup != null) return dup;
    final id = '${role.name.substring(0, 2)}${_seq++}';
    accounts.add(Account(
        user: _build(role, id, name.trim(), email.trim(), identity, extra.trim()),
        password: password,
        created: DateTime.now()));
    _log('Pengguna', 'Menambah pengguna ${name.trim()} (${role.label})');
    notifyListeners();
    return null;
  }

  String? updateUser(String id, {required String name, required String email, String? extra}) {
    final a = accountOf(id)!;
    final dup = _duplicate(a.user.role, email, a.user.identityValue, exceptId: id);
    if (dup != null && dup.startsWith('Email')) return dup;
    a.user = a.user.withProfile(name: name.trim(), email: email.trim(), extra: extra?.trim());
    if (currentUser?.id == id) currentUser = a.user;
    _log('Pengguna', 'Mengubah data pengguna ${a.user.name}');
    notifyListeners();
    return null;
  }

  void toggleActive(String id) {
    final a = accountOf(id)!;
    a.active = !a.active;
    _log('Pengguna', '${a.active ? 'Mengaktifkan' : 'Menonaktifkan'} akun ${a.user.name}');
    notifyListeners();
  }

  void deleteUser(String id) {
    final a = accountOf(id)!;
    accounts.remove(a);
    _log('Pengguna', 'Menghapus akun ${a.user.name}');
    notifyListeners();
  }

  String resetPasswordSim(String id) {
    final a = accountOf(id)!;
    a.password = 'Sipintar@2026';
    _log('Pengguna', 'Mereset kata sandi ${a.user.name}');
    notifyListeners();
    return a.password;
  }
}
