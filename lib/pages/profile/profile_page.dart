import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Password Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Saat Ini'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (newPass.text.isNotEmpty && newPass.text == confirmPass.text) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diperbarui.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthStore>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('beranda');
            }
          },
        ),
        title: const Text('Profil Pengguna'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar & Nama Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user?.initials ?? '?',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? 'Pengguna',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.role.label ?? 'Siswa',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data Identitas
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data Identitas Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 20),
                        _buildProfileTile(
                          icon: Icons.badge_outlined,
                          label: user?.identityLabel ?? 'ID',
                          value: user?.identityValue ?? '-',
                        ),
                        if (user?.extraLabel != null)
                          _buildProfileTile(
                            icon: Icons.school_outlined,
                            label: user!.extraLabel!,
                            value: user.extraValue ?? '-',
                          ),
                        _buildProfileTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Status Face Profile Biometrik
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Keamanan & Biometrik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.face_retouching_natural, color: Colors.green, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Face Profile',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    'Aktif & Terdaftar (Wajib sebelum submit peminjaman)',
                                    style: TextStyle(fontSize: 11.5, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pengaturan Akun
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
                          title: const Text('Ubah Password', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Keluar dari Akun', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.red)),
                          onTap: () async {
                            final ok = await confirm(context,
                                title: 'Keluar dari akun?',
                                message: 'Anda perlu masuk lagi untuk menggunakan aplikasi.',
                                confirmLabel: 'Keluar',
                                danger: true);
                            if (!ok || !context.mounted) return;
                            final nav = Navigator.of(context, rootNavigator: true);
                            auth.logout();
                            nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
