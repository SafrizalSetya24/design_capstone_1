import 'package:flutter/material.dart';

enum UserRole { siswa, guru, sapras, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.siswa => 'Siswa',
        UserRole.guru => 'Guru',
        UserRole.sapras => 'Sapras',
        UserRole.admin => 'Admin',
      };
}

class ProfileField {
  final String label;
  final String value;
  final IconData icon;
  const ProfileField(this.label, this.value, this.icon);
}

/// Identitas Siswa dan Guru dipisah: Siswa = NIS + kelas, Guru = NIK + jabatan/mapel.
abstract class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  const AppUser({required this.id, required this.name, required this.email, required this.role});

  String get identityLabel;
  String get identityValue;
  String get profileSectionTitle;
  String? get extraLabel => null;
  String? get extraValue => null;
  List<ProfileField> get profileFields;
  AppUser withProfile({required String name, required String email, String? extra});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

class Siswa extends AppUser {
  final String nis;
  final String kelas;
  const Siswa({required super.id, required super.name, required super.email, required this.nis, required this.kelas})
      : super(role: UserRole.siswa);
  @override
  String get identityLabel => 'NIS';
  @override
  String get identityValue => nis;
  @override
  String get profileSectionTitle => 'Data Siswa';
  @override
  String? get extraLabel => 'Kelas';
  @override
  String? get extraValue => kelas;
  @override
  List<ProfileField> get profileFields => [
        ProfileField('Nama lengkap', name, Icons.person_outline),
        ProfileField('Email', email, Icons.mail_outline),
        ProfileField('NIS', nis, Icons.badge_outlined),
        ProfileField('Kelas', kelas, Icons.school_outlined),
      ];
  @override
  AppUser withProfile({required String name, required String email, String? extra}) =>
      Siswa(id: id, name: name, email: email, nis: nis, kelas: extra ?? kelas);
}

class Guru extends AppUser {
  final String nik;
  final String mataPelajaran;
  const Guru({required super.id, required super.name, required super.email, required this.nik, required this.mataPelajaran})
      : super(role: UserRole.guru);
  @override
  String get identityLabel => 'NIK';
  @override
  String get identityValue => nik;
  @override
  String get profileSectionTitle => 'Data Guru';
  @override
  String? get extraLabel => 'Jabatan / mapel';
  @override
  String? get extraValue => mataPelajaran;
  @override
  List<ProfileField> get profileFields => [
        ProfileField('Nama lengkap', name, Icons.person_outline),
        ProfileField('Email', email, Icons.mail_outline),
        ProfileField('NIK', nik, Icons.badge_outlined),
        ProfileField('Jabatan / mapel', mataPelajaran, Icons.menu_book_outlined),
      ];
  @override
  AppUser withProfile({required String name, required String email, String? extra}) =>
      Guru(id: id, name: name, email: email, nik: nik, mataPelajaran: extra ?? mataPelajaran);
}

class SaprasUser extends AppUser {
  final String idPegawai;
  const SaprasUser({required super.id, required super.name, required super.email, required this.idPegawai})
      : super(role: UserRole.sapras);
  @override
  String get identityLabel => 'ID Pegawai';
  @override
  String get identityValue => idPegawai;
  @override
  String get profileSectionTitle => 'Data Sapras';
  @override
  List<ProfileField> get profileFields => [
        ProfileField('Nama lengkap', name, Icons.person_outline),
        ProfileField('Email', email, Icons.mail_outline),
        ProfileField('ID Pegawai', idPegawai, Icons.badge_outlined),
      ];
  @override
  AppUser withProfile({required String name, required String email, String? extra}) =>
      SaprasUser(id: id, name: name, email: email, idPegawai: idPegawai);
}

class AdminUser extends AppUser {
  final String idPegawai;
  const AdminUser({required super.id, required super.name, required super.email, required this.idPegawai})
      : super(role: UserRole.admin);
  @override
  String get identityLabel => 'ID Admin';
  @override
  String get identityValue => idPegawai;
  @override
  String get profileSectionTitle => 'Data Admin';
  @override
  List<ProfileField> get profileFields => [
        ProfileField('Nama lengkap', name, Icons.person_outline),
        ProfileField('Email', email, Icons.mail_outline),
        ProfileField('ID Admin', idPegawai, Icons.badge_outlined),
      ];
  @override
  AppUser withProfile({required String name, required String email, String? extra}) =>
      AdminUser(id: id, name: name, email: email, idPegawai: idPegawai);
}

class Account {
  AppUser user;
  String password;
  bool active;
  final DateTime created;
  DateTime? lastLogin;
  bool emailVerified;
  Account({
    required this.user,
    required this.password,
    this.active = true,
    required this.created,
    this.lastLogin,
    this.emailVerified = true,
  });
}
