import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/sapras/borrowing/borrowing_list_page.dart';
import 'package:sipintar/pages/sapras/return/return_list_page.dart';
import 'package:sipintar/pages/sapras/inventory/inventory_list_page.dart';
import 'package:sipintar/pages/sapras/consumables/consumable_list_page.dart';
import 'package:sipintar/pages/sapras/repair/repair_list_page.dart';
import 'package:sipintar/pages/sapras/notifications/notification_page.dart';
import 'package:sipintar/pages/sapras/borrowing/borrowing_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class SaprasDashboardPage extends StatelessWidget {
  const SaprasDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = context.watch<LoanStore>();
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final notifs = context.watch<NotificationStore>();
    final user = context.watch<AuthStore>().currentUser;

    // Hitung Metrik Operasional
    final waitingApproval = loans.withStatus({LoanStatus.menungguPersetujuan});
    final activeBorrowed = loans.withStatus({LoanStatus.sedangDipinjam, LoanStatus.menungguPengembalian});
    final approvedWaitingHandover = loans.withStatus({LoanStatus.disetujui});
    final repairCount = inv.repairRecords.where((r) => r.status != RepairStatus.selesai).length;
    final lowStockCount = cons.lowStock.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Operasional Sapras'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi Sapras',
            icon: Badge(
              isLabelVisible: user != null && notifs.unread(user.id) > 0,
              label: Text('${user == null ? 0 : notifs.unread(user.id)}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SaprasNotificationPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Selamat Datang Petugas
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Panel Pengelola Sarana & Prasarana',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            user?.name ?? 'Petugas Sapras',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'SMK Muhammadiyah Kramat',
                            style: TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Cards Row (5 Indikator Sesuai Bagian 18)
              Text('Ringkasan Operasional Hari Ini', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMetricCard(
                        width: isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2,
                        title: 'Menunggu Approval',
                        value: '${waitingApproval.length}',
                        subtitle: 'SLA Max 2 Jam',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                        alert: waitingApproval.isNotEmpty,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SaprasBorrowingListPage(initialTab: 0)),
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2,
                        title: 'Siap Diserahkan',
                        value: '${approvedWaitingHandover.length}',
                        subtitle: 'Disetujui',
                        icon: Icons.qr_code_scanner,
                        color: Colors.blue,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SaprasBorrowingListPage(initialTab: 1)),
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2,
                        title: 'Sedang Dipinjam',
                        value: '${activeBorrowed.length}',
                        subtitle: 'Perlu Pengembalian',
                        icon: Icons.devices,
                        color: Colors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SaprasReturnListPage()),
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2,
                        title: 'Perlu Perbaikan',
                        value: '$repairCount',
                        subtitle: 'Tiket Servis',
                        icon: Icons.build_circle_outlined,
                        color: Colors.red,
                        alert: repairCount > 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SaprasRepairListPage()),
                        ),
                      ),
                      _buildMetricCard(
                        width: isWide ? (constraints.maxWidth - 48) / 5 : (constraints.maxWidth - 12) / 2,
                        title: 'Stok Menipis',
                        value: '$lowStockCount',
                        subtitle: 'Barang Habis Pakai',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.deepOrange,
                        alert: lowStockCount > 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SaprasConsumableListPage()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Menu Navigasi Cepat Sapras (Bagian 18)
              Text('Menu Manajemen Sapras', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 6 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _buildQuickAction(
                    context,
                    title: 'Peminjaman',
                    icon: Icons.assignment_outlined,
                    color: Colors.indigo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasBorrowingListPage()),
                    ),
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Pengembalian',
                    icon: Icons.keyboard_return_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasReturnListPage()),
                    ),
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Inventaris Unit',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasInventoryListPage()),
                    ),
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Habis Pakai',
                    icon: Icons.draw_outlined,
                    color: Colors.amber.shade800,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasConsumableListPage()),
                    ),
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Perbaikan',
                    icon: Icons.build_outlined,
                    color: Colors.redAccent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasRepairListPage()),
                    ),
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Notifikasi',
                    icon: Icons.notifications_active_outlined,
                    color: Colors.purple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasNotificationPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pengajuan Terbaru yang Perlu Respon Cepat (SLA 2 Jam)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Perlu Respon Segera (SLA 2 Jam)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaprasBorrowingListPage(initialTab: 0)),
                    ),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (waitingApproval.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Tidak ada pengajuan peminjaman yang menunggu persetujuan saat ini.',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ),
                )
              else
                ...waitingApproval.take(3).map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      req.id,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${req.borrower.name} (${req.borrower.identityValue})',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(req.summary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                CountdownBadge(deadline: req.expiresAt),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SaprasBorrowingDetailPage(request: req)),
                            ),
                            child: const Text('Review', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool alert = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert ? color.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
            width: alert ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1),
            Text(subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
