import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/admin/users/user_list_page.dart';
import 'package:sipintar/pages/admin/roles/role_page.dart';
import 'package:sipintar/pages/admin/categories/category_page.dart';
import 'package:sipintar/pages/admin/item_types/item_type_page.dart';
import 'package:sipintar/pages/admin/locations/location_page.dart';
import 'package:sipintar/pages/admin/audit_logs/audit_log_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthStore>();
    final inv = context.watch<InventoryStore>();
    final audit = context.watch<AuditStore>();

    final totalUsers = auth.users.length;
    final totalCategories = inv.categories.length;
    final totalModels = inv.items.length;
    final totalLocations = inv.locations.length;
    final totalLogs = audit.entries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard & Master Data'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administrator Sistem', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('inventarisMuhamka', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 2),
                          Text('SMK Muhammadiyah Kramat (Satu Sekolah)', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Stats
              Text('Statistik Master Data', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(width: cardWidth, title: 'Total Pengguna', value: '$totalUsers', icon: Icons.people_outline, color: Colors.blue),
                      _buildStatCard(width: cardWidth, title: 'Kategori Master', value: '$totalCategories', icon: Icons.category_outlined, color: Colors.teal),
                      _buildStatCard(width: cardWidth, title: 'Model Barang', value: '$totalModels', icon: Icons.devices_other, color: Colors.amber.shade800),
                      _buildStatCard(width: cardWidth, title: 'Lokasi & Ruang', value: '$totalLocations', icon: Icons.place_outlined, color: Colors.indigo),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Menu Master Data Grid (Bagian 34 & 35)
              Text('Menu Pengelolaan Master Data', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: MediaQuery.of(context).size.width > 700 ? 1.4 : 1.15,
                children: [
                  _buildAdminCard(
                    title: 'Kelola User',
                    subtitle: 'Akun Siswa, Guru & Reset Password',
                    icon: Icons.manage_accounts_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminUserListPage()),
                    ),
                  ),
                  _buildAdminCard(
                    title: 'Role Pengguna',
                    subtitle: 'Hak Akses Student, Guru, Sapras, Admin',
                    icon: Icons.shield_outlined,
                    color: Colors.purple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminRolePage()),
                    ),
                  ),
                  _buildAdminCard(
                    title: 'Kategori Barang',
                    subtitle: 'Elektronik, ATK, Laboratorium',
                    icon: Icons.category_outlined,
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminCategoryPage()),
                    ),
                  ),
                  _buildAdminCard(
                    title: 'Model / Jenis Barang',
                    subtitle: 'Laptop, Proyektor, Kamera, Spidol',
                    icon: Icons.devices_other,
                    color: Colors.amber.shade800,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminItemTypePage()),
                    ),
                  ),
                  _buildAdminCard(
                    title: 'Lokasi & Ruangan',
                    subtitle: 'Lab RPL, Ruang Guru, Gudang',
                    icon: Icons.place_outlined,
                    color: Colors.indigo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminLocationPage()),
                    ),
                  ),
                  _buildAdminCard(
                    title: 'Audit Log Sistem',
                    subtitle: '$totalLogs rekaman jejak aktivitas',
                    icon: Icons.history,
                    color: Colors.redAccent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminAuditLogPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
