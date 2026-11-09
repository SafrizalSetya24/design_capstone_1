import 'package:flutter/material.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminRolePage extends StatelessWidget {
  const AdminRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    const roles = [
      (
        'Student (Siswa)',
        'Login menggunakan NIS + Password, Face Registration jika belum terdaftar, melihat katalog model & ketersediaan, menambah ke keranjang (mixed), verifikasi wajah sebelum submit, memantau batas persetujuan 2 jam, riwayat, dan notifikasi.',
        Icons.school_outlined,
        Colors.blue,
      ),
      (
        'Teacher (Guru)',
        'Login menggunakan NIK + Password, Face Registration, melihat katalog model & ketersediaan, multi-item cart, verifikasi wajah sebelum submit, riwayat peminjaman perlengkapan mengajar.',
        Icons.person_outline,
        Colors.teal,
      ),
      (
        'Sapras (Sarana Prasarana)',
        'Dashboard operasional, approval & rejection peminjaman (SLA 2 jam), penyerahan barang (Handover: Scan Barcode unit fisik & potong stok habis pakai), inspeksi pengembalian (Return Inspection), tiket perbaikan (Repair Flow), serta manajemen stok.',
        Icons.build_outlined,
        Colors.amber,
      ),
      (
        'Admin (Administrator)',
        'Manajemen pengguna (buat akun Siswa & Guru, reset password), pengaturan master data (Role, Kategori Barang, Jenis/Model Barang, Lokasi), dan pemantauan sistem audit log.',
        Icons.admin_panel_settings_outlined,
        Colors.purple,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Role Pengguna'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final r = roles[idx];
            return AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: r.$4.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(r.$3, color: r.$4, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(r.$2, style: const TextStyle(fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
