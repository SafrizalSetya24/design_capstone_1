import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/data/stores/audit_store.dart';

// State management autentikasi dan sesi pengguna (Siswa, Guru, Sapras, Admin)
class AuthStore extends ChangeNotifier {
  AuthStore(this._auditStore);

  final AuditStore _auditStore;

  /// Daftar akun di dalam sistem (diambil dari data dummy awal)
  final List<Account> accounts = DummyData.accounts();

  /// Pengguna yang sedang aktif login di sesi saat ini
  AppUser? currentUser;

  int _sequenceCounter = 100;

  /// Daftar seluruh entitas profil pengguna
  List<AppUser> get users => accounts.map((account) => account.user).toList();

  // Pencatatan audit log aktivitas pengguna
  void _recordAuditLog(String actionType, String detailMessage) {
    final user = currentUser;
    if (user != null) {
      _auditStore.log(user.name, user.role.label, actionType, detailMessage);
    }
  }

  // Pencarian akun berdasarkan email, NIS, NIK/NUPTK, atau ID
  Account? findAccount(String searchQuery) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return null;

    // Alias helper agar login cepat via role juga tetap dapat bekerja
    if (normalizedQuery == 'siswa@sipintar.id' || normalizedQuery == '2024001234') {
      return accountOf('sw1');
    }
    if (normalizedQuery == 'guru@sipintar.id' || normalizedQuery == '3374012345670001') {
      return accountOf('gr1');
    }
    if (normalizedQuery == 'sapras@sipintar.id' || normalizedQuery == 'spr-007') {
      return accountOf('sp1');
    }
    if (normalizedQuery == 'admin@sipintar.id' || normalizedQuery == 'adm-001') {
      return accountOf('ad1');
    }

    for (final account in accounts) {
      if (account.user.email.toLowerCase() == normalizedQuery) return account;
      if (account.user.identityValue.toLowerCase() == normalizedQuery) return account;
      if (account.user.id.toLowerCase() == normalizedQuery) return account;
    }
    return null;
  }

  Account? accountOf(String userId) {
    for (final account in accounts) {
      if (account.user.id == userId) return account;
    }
    return null;
  }

  Account? _byEmail(String email) => findAccount(email);

  bool emailExists(String email) => _byEmail(email) != null;

  // Login dan logout
  String? login(String identifier, String password) {
    final account = findAccount(identifier);
    if (account == null || account.password != password) {
      return 'Nomor Identitas (NIS/NIK), Email, atau password tidak sesuai. Periksa kembali lalu coba lagi.';
    }
    if (!account.active) {
      return 'Akun Anda dinonaktifkan. Hubungi Admin sekolah untuk mengaktifkannya kembali.';
    }
    if (!account.emailVerified) {
      return 'Email belum diverifikasi. Selesaikan verifikasi email terlebih dahulu.';
    }

    account.lastLogin = DateTime.now();
    currentUser = account.user;
    _recordAuditLog('Login', 'Masuk ke aplikasi');
    notifyListeners();
    return null;
  }

  void logout() {
    _recordAuditLog('Logout', 'Keluar dari aplikasi');
    currentUser = null;
    notifyListeners();
  }

  void demoLogin(String userId) {
    final account = accountOf(userId);
    if (account != null) {
      currentUser = account.user;
      notifyListeners();
    }
  }

  // Verifikasi biometrik wajah
  bool isFaceRegistered([String? userId]) {
    final targetUserId = userId ?? currentUser?.id;
    if (targetUserId == null) return false;
    return accountOf(targetUserId)?.faceRegistered ?? false;
  }

  void setFaceRegistered(bool registered, [String? userId]) {
    final targetUserId = userId ?? currentUser?.id;
    if (targetUserId == null) return;

    final targetAccount = accountOf(targetUserId);
    if (targetAccount != null) {
      targetAccount.faceRegistered = registered;
      _recordAuditLog(
        registered ? 'Daftar Wajah' : 'Reset Wajah',
        'Data wajah ${targetAccount.user.name} ${registered ? "berhasil didaftarkan" : "direset"}',
      );
      notifyListeners();
    }
  }

  void registerFace() => setFaceRegistered(true);

  // Registrasi user
  AppUser _buildUserEntity(
    UserRole role,
    String id,
    String name,
    String email,
    String identity,
    String extra,
  ) =>
      switch (role) {
        UserRole.siswa =>
          Siswa(id: id, name: name, email: email, nis: identity, kelas: extra),
        UserRole.guru => Guru(
            id: id,
            name: name,
            email: email,
            nik: identity,
            mataPelajaran: extra,
          ),
        UserRole.sapras =>
          SaprasUser(id: id, name: name, email: email, idPegawai: identity),
        UserRole.admin =>
          AdminUser(id: id, name: name, email: email, idPegawai: identity),
      };

  String? _checkDuplicate(
    UserRole role,
    String email,
    String identity, {
    String? exceptId,
  }) {
    for (final account in accounts) {
      if (account.user.id == exceptId) continue;
      if (account.user.email.toLowerCase() == email.trim().toLowerCase()) {
        return 'Email sudah terdaftar.';
      }
      if (account.user.role == role && account.user.identityValue == identity) {
        return '${account.user.identityLabel} sudah terdaftar.';
      }
    }
    return null;
  }

  String? register({
    required UserRole role,
    required String name,
    required String email,
    required String identity,
    required String extra,
    required String password,
  }) {
    final duplicateError = _checkDuplicate(role, email, identity);
    if (duplicateError != null) return duplicateError;

    final id = '${role == UserRole.siswa ? 'sw' : 'gr'}${_sequenceCounter++}';
    accounts.add(
      Account(
        user: _buildUserEntity(role, id, name.trim(), email.trim(), identity, extra.trim()),
        password: password,
        created: DateTime.now(),
        emailVerified: false,
        faceRegistered: false,
      ),
    );
    _auditStore.log(
      name.trim(),
      role.label,
      'Registrasi',
      'Membuat akun ${role.label}',
    );
    notifyListeners();
    return null;
  }

  void registerSiswa({
    required String nis,
    required String name,
    required String kelas,
    required String email,
    required String password,
  }) {
    register(
      role: UserRole.siswa,
      name: name,
      email: email,
      identity: nis,
      extra: kelas,
      password: password,
    );
    verifyEmail(email);
  }

  void registerGuru({
    required String nik,
    required String name,
    required String jabatan,
    required String email,
    required String password,
  }) {
    register(
      role: UserRole.guru,
      name: name,
      email: email,
      identity: nik,
      extra: jabatan,
      password: password,
    );
    verifyEmail(email);
  }

  void verifyEmail(String email) {
    _byEmail(email)?.emailVerified = true;
    notifyListeners();
  }

  bool resetPassword(String email, String newPassword) {
    final targetAccount = _byEmail(email);
    if (targetAccount == null) return false;
    targetAccount.password = newPassword;
    notifyListeners();
    return true;
  }

  String? changePassword(String oldPassword, String newPassword) {
    final currentAccount = accountOf(currentUser!.id)!;
    if (currentAccount.password != oldPassword) {
      return 'Kata sandi lama tidak sesuai.';
    }
    currentAccount.password = newPassword;
    _recordAuditLog('Akun', 'Mengubah kata sandi');
    notifyListeners();
    return null;
  }

  String? updateProfile({
    required String name,
    required String email,
    String? extra,
  }) {
    final activeUser = currentUser!;
    final duplicateError = _checkDuplicate(
      activeUser.role,
      email,
      activeUser.identityValue,
      exceptId: activeUser.id,
    );
    if (duplicateError != null && duplicateError.startsWith('Email')) {
      return duplicateError;
    }

    final updatedUser = activeUser.withProfile(
      name: name.trim(),
      email: email.trim(),
      extra: extra?.trim(),
    );
    accountOf(activeUser.id)!.user = updatedUser;
    currentUser = updatedUser;
    _recordAuditLog('Akun', 'Memperbarui profil');
    notifyListeners();
    return null;
  }

  // Kelola pengguna admin
  int countRole(UserRole role) =>
      accounts.where((account) => account.user.role == role).length;

  String? addUser({
    required UserRole role,
    required String name,
    required String email,
    required String identity,
    required String extra,
    required String password,
  }) {
    final duplicateError = _checkDuplicate(role, email, identity);
    if (duplicateError != null) return duplicateError;

    final id = '${role.name.substring(0, 2)}${_sequenceCounter++}';
    accounts.add(
      Account(
        user: _buildUserEntity(role, id, name.trim(), email.trim(), identity, extra.trim()),
        password: password,
        created: DateTime.now(),
      ),
    );
    _recordAuditLog('Pengguna', 'Menambah pengguna ${name.trim()} (${role.label})');
    notifyListeners();
    return null;
  }

  String? updateUser(
    String id, {
    required String name,
    required String email,
    String? extra,
  }) {
    final targetAccount = accountOf(id)!;
    final duplicateError = _checkDuplicate(
      targetAccount.user.role,
      email,
      targetAccount.user.identityValue,
      exceptId: id,
    );
    if (duplicateError != null && duplicateError.startsWith('Email')) {
      return duplicateError;
    }

    targetAccount.user = targetAccount.user.withProfile(
      name: name.trim(),
      email: email.trim(),
      extra: extra?.trim(),
    );
    if (currentUser?.id == id) {
      currentUser = targetAccount.user;
    }
    _recordAuditLog('Pengguna', 'Mengubah data pengguna ${targetAccount.user.name}');
    notifyListeners();
    return null;
  }

  void toggleActive(String id) {
    final targetAccount = accountOf(id)!;
    targetAccount.active = !targetAccount.active;
    _recordAuditLog(
      'Pengguna',
      '${targetAccount.active ? 'Mengaktifkan' : 'Menonaktifkan'} akun ${targetAccount.user.name}',
    );
    notifyListeners();
  }

  void deleteUser(String id) {
    final targetAccount = accountOf(id)!;
    accounts.remove(targetAccount);
    _recordAuditLog('Pengguna', 'Menghapus akun ${targetAccount.user.name}');
    notifyListeners();
  }

  String resetPasswordSim(String id) {
    final targetAccount = accountOf(id)!;
    targetAccount.password = 'Sipintar@2026';
    _recordAuditLog('Pengguna', 'Mereset kata sandi ${targetAccount.user.name}');
    notifyListeners();
    return targetAccount.password;
  }
}
