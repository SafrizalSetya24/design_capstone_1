import 'package:flutter/material.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/features/auth/auth_layout.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  Widget _option(BuildContext c, IconData icon, String title, String desc,
          List<String> ids, String route) =>
      AppCard(
        onTap: () => Navigator.of(c).pushNamed(route),
        child: Row(children: [
          CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.blue.withValues(alpha: 0.12),
              child: Icon(icon, color: AppColors.navy)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final i in ids)
                  Chip(
                      label: Text(i, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact)
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Daftar sebagai',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
        const SizedBox(height: 4),
        const Text('Pilih jenis akun. Data identitas Siswa dan Guru berbeda.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        _option(
            context,
            Icons.school_outlined,
            'Siswa',
            'Peminjam dari kalangan peserta didik.',
            const ['NIS', 'Kelas'],
            AppRoutes.registerSiswa),
        const SizedBox(height: AppSpacing.md),
        _option(
            context,
            Icons.person_pin_outlined,
            'Guru',
            'Peminjam dari kalangan tenaga pendidik.',
            const ['NIK', 'Jabatan / mapel'],
            AppRoutes.registerGuru),
      ]),
    );
  }
}
