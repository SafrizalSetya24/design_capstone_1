import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/admin/users/student_form_page.dart';
import 'package:sipintar/pages/admin/users/teacher_form_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetPassword(BuildContext context, AuthStore auth, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password ${user.name}?'),
        content: Text('Password pengguna ${user.name} akan di-reset ke default sekolah: "muhamka123".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              auth.resetPassword(user.email, "muhamka123");
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password untuk ${user.name} berhasil di-reset.')),
              );
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    final siswaList = auth.users.whereType<Siswa>().where((s) {
      if (_search.isEmpty) return true;
      return s.name.toLowerCase().contains(_search) || s.nis.contains(_search) || s.kelas.toLowerCase().contains(_search);
    }).toList();

    final guruList = auth.users.whereType<Guru>().where((g) {
      if (_search.isEmpty) return true;
      return g.name.toLowerCase().contains(_search) || g.nik.contains(_search) || g.jabatan.toLowerCase().contains(_search);
    }).toList();

    final staffList = auth.users.where((u) => u is! Siswa && u is! Guru).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna (User Management)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Siswa (${siswaList.length})'),
            Tab(text: 'Guru (${guruList.length})'),
            Tab(text: 'Staff (${staffList.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama, NIS, NIK, atau kelas...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                            : null,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Siswa
                  _buildUserList(
                    context,
                    siswaList,
                    onEdit: (u) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdminStudentFormPage(student: u as Siswa)),
                    ),
                    onReset: (u) => _resetPassword(context, auth, u),
                  ),

                  // Tab Guru
                  _buildUserList(
                    context,
                    guruList,
                    onEdit: (u) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdminTeacherFormPage(teacher: u as Guru)),
                    ),
                    onReset: (u) => _resetPassword(context, auth, u),
                  ),

                  // Tab Staff
                  _buildUserList(
                    context,
                    staffList,
                    onEdit: null,
                    onReset: (u) => _resetPassword(context, auth, u),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
        onPressed: () {
          final isGuruTab = _tabController.index == 1;
          if (isGuruTab) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminTeacherFormPage()));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminStudentFormPage()));
          }
        },
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<AppUser> users, {
    void Function(AppUser)? onEdit,
    required void Function(AppUser) onReset,
  }) {
    if (users.isEmpty) {
      return const Center(child: Text('Tidak ada pengguna yang cocok.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final u = users[idx];

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  u.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      '${u.identityLabel}: ${u.identityValue} • ${u.extraValue ?? u.role.label}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(u.email, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit' && onEdit != null) onEdit(u);
                  if (val == 'reset') onReset(u);
                },
                itemBuilder: (ctx) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Ubah Data')])),
                  const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.lock_reset, size: 16), SizedBox(width: 8), Text('Reset Password')])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
