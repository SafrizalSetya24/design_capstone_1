import 'package:flutter/material.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/home/home_page.dart';
import 'package:sipintar/pages/catalog/item_category_page.dart';
import 'package:sipintar/pages/cart/cart_page.dart';
import 'package:sipintar/pages/history/borrowing_history_page.dart';
import 'package:sipintar/pages/notification/notification_page.dart';
import 'package:sipintar/pages/profile/profile_page.dart';
import 'package:sipintar/pages/review/user_feedback_page.dart';
import 'package:sipintar/pages/review/admin_review_summary_page.dart';
import 'package:sipintar/pages/admin/reviews/admin_review_management_page.dart';

// Definisi menu navigasi aplikasi berdasarkan peran pengguna (Siswa, Guru, Sapras, Admin)

// Halaman-halaman Operasional Sarana & Prasarana (Sarpras)
import 'package:sipintar/pages/sapras/dashboard/dashboard_page.dart'
    as sapras_dash;
import 'package:sipintar/pages/sapras/borrowing/borrowing_list_page.dart'
    as sapras_borrow;
import 'package:sipintar/pages/sapras/return/return_list_page.dart'
    as sapras_return;
import 'package:sipintar/pages/sapras/inventory/inventory_list_page.dart'
    as sapras_inv;
import 'package:sipintar/pages/sapras/consumables/consumable_list_page.dart'
    as sapras_cons;
import 'package:sipintar/pages/sapras/repair/repair_list_page.dart'
    as sapras_repair;
import 'package:sipintar/pages/sapras/notifications/notification_page.dart'
    as sapras_notif;

// Halaman-halaman Master Data Administrator Sistem
import 'package:sipintar/pages/admin/dashboard/dashboard_page.dart'
    as admin_dash;
import 'package:sipintar/pages/admin/users/user_list_page.dart' as admin_users;
import 'package:sipintar/pages/admin/roles/role_page.dart' as admin_roles;
import 'package:sipintar/pages/admin/categories/category_page.dart'
    as admin_cat;
import 'package:sipintar/pages/admin/item_types/item_type_page.dart'
    as admin_types;
import 'package:sipintar/pages/admin/locations/location_page.dart' as admin_loc;
import 'package:sipintar/pages/admin/audit_logs/audit_log_page.dart'
    as admin_audit;

/// Model data untuk satu item navigasi pada Sidebar, NavigationRail, atau BottomNavBar
class NavItem {
  final String id;
  final String label;
  final String short;
  final String group;
  final IconData icon;
  final IconData selectedIcon;
  final bool bottom;
  final Widget Function(int argument) builder;

  const NavItem({
    required this.id,
    required this.label,
    String? short,
    required this.group,
    required this.icon,
    IconData? selectedIcon,
    this.bottom = false,
    required this.builder,
  })  : short = short ?? label,
        selectedIcon = selectedIcon ?? icon;
}

// Menu navigasi berdasarkan peran pengguna
List<NavItem> navItemsFor(AppUser currentUser, SettingsStore settingsStore) {
  final userRole = currentUser.role;

  switch (userRole) {
    // Menu siswa & guru
    case UserRole.siswa:
    case UserRole.guru:
      return [
        NavItem(
          id: 'beranda',
          label: 'Beranda',
          group: 'Menu',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          bottom: true,
          builder: (_) => const HomePage(),
        ),
        NavItem(
          id: 'katalog',
          label: 'Katalog',
          group: 'Menu',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          bottom: true,
          builder: (_) => const ItemCategoryPage(),
        ),
        NavItem(
          id: 'keranjang',
          label: 'Keranjang',
          group: 'Menu',
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          bottom: true,
          builder: (_) => const CartPage(),
        ),
        NavItem(
          id: 'riwayat',
          label: 'Riwayat',
          group: 'Menu',
          icon: Icons.history,
          bottom: true,
          builder: (_) => const BorrowingHistoryPage(),
        ),
        NavItem(
          id: 'notifikasi',
          label: 'Notifikasi',
          group: 'Menu',
          icon: Icons.notifications_none,
          selectedIcon: Icons.notifications,
          bottom: true,
          builder: (_) => const NotificationPage(),
        ),
        NavItem(
          id: 'profil',
          label: 'Profil',
          group: 'Menu',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          bottom: false,
          builder: (_) => const ProfilePage(),
        ),
        NavItem(
          id: 'ulasan',
          label: 'Kritik & Saran',
          group: 'Lainnya',
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review,
          bottom: false,
          builder: (_) => const UserFeedbackPage(),
        ),
      ];

    // Menu petugas sarpras
    case UserRole.sapras:
      return [
        NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          group: 'Operasional',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const sapras_dash.SaprasDashboardPage(),
        ),
        NavItem(
          id: 'peminjaman',
          label: 'Peminjaman',
          group: 'Operasional',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          builder: (_) => const sapras_borrow.SaprasBorrowingListPage(),
        ),
        NavItem(
          id: 'pengembalian',
          label: 'Pengembalian Unit',
          group: 'Operasional',
          icon: Icons.keyboard_return_rounded,
          selectedIcon: Icons.keyboard_return,
          builder: (_) => const sapras_return.SaprasReturnListPage(),
        ),
        NavItem(
          id: 'inventaris',
          label: 'Inventaris Per Unit',
          group: 'Gudang',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: (_) => const sapras_inv.SaprasInventoryListPage(),
        ),
        NavItem(
          id: 'habis_pakai',
          label: 'Barang Habis Pakai',
          group: 'Gudang',
          icon: Icons.draw_outlined,
          selectedIcon: Icons.draw,
          builder: (_) => const sapras_cons.SaprasConsumableListPage(),
        ),
        NavItem(
          id: 'perbaikan',
          label: 'Perbaikan (Repair)',
          group: 'Gudang',
          icon: Icons.build_outlined,
          selectedIcon: Icons.build,
          builder: (_) => const sapras_repair.SaprasRepairListPage(),
        ),
        NavItem(
          id: 'notifikasi',
          label: 'Notifikasi Sapras',
          group: 'Akun',
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          builder: (_) => const sapras_notif.SaprasNotificationPage(),
        ),
        NavItem(
          id: 'profil',
          label: 'Profil Petugas',
          group: 'Akun',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          builder: (_) => const ProfilePage(),
        ),
        NavItem(
          id: 'ulasan',
          label: 'Rekap Ulasan & Evaluasi',
          group: 'Akun',
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          builder: (_) => const AdminReviewSummaryPage(),
        ),
      ];

    // Menu administrator sistem
    case UserRole.admin:
      return [
        NavItem(
          id: 'dashboard',
          label: 'Dashboard Admin',
          group: 'Utama',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const admin_dash.AdminDashboardPage(),
        ),
        NavItem(
          id: 'users',
          label: 'Kelola User',
          group: 'Master Data',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          builder: (_) => const admin_users.AdminUserListPage(),
        ),
        NavItem(
          id: 'roles',
          label: 'Role Pengguna',
          group: 'Master Data',
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield,
          builder: (_) => const admin_roles.AdminRolePage(),
        ),
        NavItem(
          id: 'kategori',
          label: 'Kategori Barang',
          group: 'Master Data',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          builder: (_) => const admin_cat.AdminCategoryPage(),
        ),
        NavItem(
          id: 'model',
          label: 'Model / Jenis Barang',
          group: 'Master Data',
          icon: Icons.devices_other,
          selectedIcon: Icons.devices_other,
          builder: (_) => const admin_types.AdminItemTypePage(),
        ),
        NavItem(
          id: 'lokasi',
          label: 'Lokasi & Ruangan',
          group: 'Master Data',
          icon: Icons.place_outlined,
          selectedIcon: Icons.place,
          builder: (_) => const admin_loc.AdminLocationPage(),
        ),
        NavItem(
          id: 'audit',
          label: 'Audit Log Sistem',
          group: 'Sistem',
          icon: Icons.history,
          selectedIcon: Icons.history,
          builder: (_) => const admin_audit.AdminAuditLogPage(),
        ),
        NavItem(
          id: 'kelola_ulasan',
          label: 'Kelola Ulasan',
          group: 'Layanan',
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review,
          builder: (_) => const AdminReviewManagementPage(),
        ),
        NavItem(
          id: 'ulasan',
          label: 'Rekap Ulasan & Evaluasi',
          group: 'Layanan',
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          builder: (_) => const AdminReviewSummaryPage(),
        ),
        NavItem(
          id: 'profil',
          label: 'Profil Admin',
          group: 'Akun',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          builder: (_) => const ProfilePage(),
        ),
      ];
  }
}
