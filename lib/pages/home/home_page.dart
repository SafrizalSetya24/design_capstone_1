import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/catalog/item_category_page.dart';
import 'package:sipintar/pages/cart/cart_page.dart';
import 'package:sipintar/pages/history/borrowing_history_page.dart';
import 'package:sipintar/pages/notification/notification_page.dart';
import 'package:sipintar/pages/profile/profile_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthStore>().currentUser;
    final cart = context.watch<CartStore>();
    final loans = context.watch<LoanStore>();
    final notifs = context.watch<NotificationStore>();

    final myLoans = user == null ? <LoanRequest>[] : loans.forUser(user.id);
    final activeLoan = myLoans.isNotEmpty &&
            (myLoans.first.status == LoanStatus.menungguPersetujuan ||
                myLoans.first.status == LoanStatus.disetujui ||
                myLoans.first.status == LoanStatus.sedangDipinjam)
        ? myLoans.first
        : null;

    final unreadNotif = user == null ? 0 : notifs.unread(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InventarisMuhamka'),
        actions: [
          IconButton(
            tooltip: 'Keranjang',
            icon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: Badge(
              isLabelVisible: unreadNotif > 0,
              label: Text('$unreadNotif'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Sambutan
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                user?.initials ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat datang,',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    user?.name ?? 'Pengguna',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    '${user?.identityLabel ?? "ID"}: ${user?.identityValue ?? "-"} • ${user?.extraValue ?? user?.role.label ?? ""}',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  color: Colors.greenAccent, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Face Profile Terdaftar • Verifikasi Biometrik Aktif',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Alert Status Peminjaman Aktif (jika ada yang sedang menunggu approval 2 jam atau dipinjam)
                  if (activeLoan != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activeLoan.status ==
                                            LoanStatus.menungguPersetujuan
                                        ? Icons.hourglass_top_rounded
                                        : Icons.access_time_filled_rounded,
                                    color: activeLoan.status ==
                                            LoanStatus.menungguPersetujuan
                                        ? Colors.orange
                                        : AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Peminjaman Aktif',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              StatusBadge.status(activeLoan.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeLoan.summary,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jadwal: ${Format.range(activeLoan.start, activeLoan.end)}',
                            style:
                                TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                          if (activeLoan.status ==
                              LoanStatus.menungguPersetujuan) ...[
                            const SizedBox(height: 10),
                            CountdownBadge(
                              deadline: activeLoan.expiresAt,
                              onExpire: () => loans.checkExpiry(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Alur SOP Peminjaman 6 Langkah (Slide 7 PPT)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.route_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alur Peminjaman Barang (SOP 6 Langkah)',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Sesuai prosedur resmi inventaris sekolah',
                                    style: TextStyle(
                                        fontSize: 11.5, color: theme.hintColor),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Mulai Pinjam',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ItemCategoryPage()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // 6 Steps Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStepChip('1', 'Pilih Model', Icons.search),
                            _buildStepChip('2', 'Tentukan Qty', Icons.tune),
                            _buildStepChip(
                                '3', 'Keranjang', Icons.shopping_cart_outlined),
                            _buildStepChip('4', 'Jadwal & Keperluan',
                                Icons.calendar_today_outlined),
                            _buildStepChip('5', 'Verifikasi Wajah',
                                Icons.face_retouching_natural),
                            _buildStepChip('6', 'Approval Sapras',
                                Icons.check_circle_outline),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Utama (Sesuai Dokumen Spesifikasi Bagian 5)
                  Text(
                    'Layanan Peminjaman',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 900 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio:
                        MediaQuery.of(context).size.width >= 900 ? 1.2 : 1.1,
                    children: [
                      _buildMenuCard(
                        context,
                        title: 'Pinjam Barang',
                        subtitle: 'Katalog per unit & ATK',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ItemCategoryPage()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Keranjang',
                        subtitle: '${cart.itemCount} jenis barang',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.teal,
                        badgeCount: cart.itemCount,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Riwayat Peminjaman',
                        subtitle: 'Status & arsip pengajuan',
                        icon: Icons.history_rounded,
                        color: Colors.indigo,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BorrowingHistoryPage()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Profil Saya',
                        subtitle: 'Data akun & password',
                        icon: Icons.person_outline_rounded,
                        color: Colors.blueGrey,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ProfilePage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Informasi Penting / Panduan
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tata Tertib Peminjaman Sarpras',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Satu pengajuan dapat memuat beberapa barang sekaligus (Barang Per Unit & Barang Habis Pakai).\n'
                          '2. Verifikasi Wajah wajib dilakukan sesaat sebelum mengirim pengajuan peminjaman.\n'
                          '3. Batas waktu konfirmasi persetujuan oleh Sapras adalah maksimal 2 Jam setelah pengajuan dikirim.\n'
                          '4. Barang Per Unit (Laptop, Proyektor, dll) wajib dikembalikan dan diperiksa kondisinya oleh petugas Sapras.\n'
                          '5. Barang Habis Pakai (Spidol, Kertas, dll) tidak perlu dikembalikan.',
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: theme.hintColor),
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

  Widget _buildStepChip(String stepNum, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: AppColors.primary,
            child: Text(
              stepNum,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 10.5, color: Theme.of(context).hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
