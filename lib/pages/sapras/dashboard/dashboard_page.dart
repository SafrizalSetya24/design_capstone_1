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

// Dashboard operasional sarana dan prasarana (SLA approval, peminjaman, dan inventaris)
class SaprasDashboardPage extends StatelessWidget {
  const SaprasDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loanStore = context.watch<LoanStore>();
    final inventoryStore = context.watch<InventoryStore>();
    final consumableStore = context.watch<ConsumableStore>();
    final notificationStore = context.watch<NotificationStore>();
    final currentUser = context.watch<AuthStore>().currentUser;

    // Hitung metrik operasional harian
    final waitingApproval =
        loanStore.withStatus({LoanStatus.menungguPersetujuan});
    final activeBorrowed = loanStore.withStatus(
        {LoanStatus.sedangDipinjam, LoanStatus.menungguPengembalian});
    final approvedWaitingHandover =
        loanStore.withStatus({LoanStatus.disetujui});
    final repairCount = inventoryStore.repairRecords
        .where((record) => record.status != RepairStatus.selesai)
        .length;
    final lowStockCount = consumableStore.lowStock.length;

    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Dashboard Operasional Sapras'),
              actions: [
                IconButton(
                  tooltip: 'Notifikasi Sapras',
                  icon: Badge(
                    isLabelVisible: currentUser != null &&
                        notificationStore.unread(currentUser.id) > 0,
                    label: Text(
                        '${currentUser == null ? 0 : notificationStore.unread(currentUser.id)}'),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Banner profil petugas
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
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Panel Pengelola Sarana & Prasarana',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            currentUser?.name ?? 'Petugas Sapras',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'SMK Muhammadiyah Kramat',
                            style:
                                TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ringkasan metrik operasional
              Text('Ringkasan Operasional Hari Ini',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 48) / 5
                      : isTablet
                          ? (constraints.maxWidth - 24) / 3
                          : (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMetricCard(
                        width: cardWidth,
                        title: 'Menunggu Approval',
                        value: '${waitingApproval.length}',
                        subtitle: 'SLA Max 2 Jam',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                        alert: waitingApproval.isNotEmpty,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SaprasBorrowingListPage(initialTab: 0)),
                        ),
                      ),
                      _buildMetricCard(
                        width: cardWidth,
                        title: 'Siap Diserahkan',
                        value: '${approvedWaitingHandover.length}',
                        subtitle: 'Disetujui',
                        icon: Icons.qr_code_scanner,
                        color: Colors.blue,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SaprasBorrowingListPage(initialTab: 1)),
                        ),
                      ),
                      _buildMetricCard(
                        width: cardWidth,
                        title: 'Sedang Dipinjam',
                        value: '${activeBorrowed.length}',
                        subtitle: 'Perlu Pengembalian',
                        icon: Icons.devices,
                        color: Colors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasReturnListPage()),
                        ),
                      ),
                      _buildMetricCard(
                        width: cardWidth,
                        title: 'Perlu Perbaikan',
                        value: '$repairCount',
                        subtitle: 'Tiket Servis',
                        icon: Icons.build_circle_outlined,
                        color: Colors.red,
                        alert: repairCount > 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasRepairListPage()),
                        ),
                      ),
                      _buildMetricCard(
                        width: cardWidth,
                        title: 'Stok Menipis',
                        value: '$lowStockCount',
                        subtitle: 'Barang Habis Pakai',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.deepOrange,
                        alert: lowStockCount > 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasConsumableListPage()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Menu navigasi cepat
              Text('Menu Manajemen Sapras',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columnCount = constraints.maxWidth > 650 ? 6 : 3;
                  return GridView.count(
                    crossAxisCount: columnCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columnCount == 6 ? 1.05 : 1.1,
                    children: [
                      _buildQuickAction(
                        context,
                        title: 'Peminjaman',
                        icon: Icons.assignment_outlined,
                        color: Colors.indigo,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasBorrowingListPage()),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        title: 'Pengembalian',
                        icon: Icons.keyboard_return_rounded,
                        color: Colors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasReturnListPage()),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        title: 'Inventaris Unit',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasInventoryListPage()),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        title: 'Habis Pakai',
                        icon: Icons.draw_outlined,
                        color: Colors.amber.shade800,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasConsumableListPage()),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        title: 'Perbaikan',
                        icon: Icons.build_outlined,
                        color: Colors.redAccent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasRepairListPage()),
                        ),
                      ),
                      _buildQuickAction(
                        context,
                        title: 'Notifikasi',
                        icon: Icons.notifications_active_outlined,
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SaprasNotificationPage()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Antrean pengajuan yang perlu respon cepat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Perlu Respon Segera (SLA 2 Jam)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const SaprasBorrowingListPage(initialTab: 0)),
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
                ...waitingApproval.take(3).map((request) {
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
                                      request.id,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '• ${request.borrower.name} (${request.borrower.identityValue})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(request.summary,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(height: 6),
                                CountdownBadge(deadline: request.expiresAt),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => SaprasBorrowingDetailPage(
                                      request: request)),
                            ),
                            child: const Text('Review',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
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
        ),
      ),
    );
  }

  // Helper kartu metrik
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
            color: alert
                ? color.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
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
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                maxLines: 1),
            Text(subtitle,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                maxLines: 1),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
