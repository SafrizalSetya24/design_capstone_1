import 'package:flutter/material.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/home/home_page.dart';
import 'package:sipintar/pages/catalog/item_category_page.dart';
import 'package:sipintar/pages/cart/cart_page.dart';
import 'package:sipintar/pages/history/borrowing_history_page.dart';
import 'package:sipintar/pages/notification/notification_page.dart';
import 'package:sipintar/pages/profile/profile_page.dart';

import 'package:sipintar/pages/sapras/dashboard/dashboard_page.dart' as sp_dash;
import 'package:sipintar/pages/sapras/borrowing/borrowing_list_page.dart' as sp_borrow;
import 'package:sipintar/pages/sapras/return/return_list_page.dart' as sp_return;
import 'package:sipintar/pages/sapras/inventory/inventory_list_page.dart' as sp_inv;
import 'package:sipintar/pages/sapras/consumables/consumable_list_page.dart' as sp_cons;
import 'package:sipintar/pages/sapras/repair/repair_list_page.dart' as sp_repair;
import 'package:sipintar/pages/sapras/notifications/notification_page.dart' as sp_notif;

import 'package:sipintar/pages/admin/dashboard/dashboard_page.dart' as adm_dash;
import 'package:sipintar/pages/admin/users/user_list_page.dart' as adm_users;
import 'package:sipintar/pages/admin/roles/role_page.dart' as adm_roles;
import 'package:sipintar/pages/admin/categories/category_page.dart' as adm_cat;
import 'package:sipintar/pages/admin/item_types/item_type_page.dart' as adm_types;
import 'package:sipintar/pages/admin/locations/location_page.dart' as adm_loc;
import 'package:sipintar/pages/admin/audit_logs/audit_log_page.dart' as adm_audit;

class NavItem {
  final String id, label, short, group;
  final IconData icon, selectedIcon;
  final bool bottom;
  final Widget Function(int arg) builder;
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

List<NavItem> navItemsFor(AppUser user, SettingsStore s) {
  final role = user.role;
  switch (role) {
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
      ];

    case UserRole.sapras:
      return [
        NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          group: 'Operasional',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const sp_dash.SaprasDashboardPage(),
        ),
        NavItem(
          id: 'peminjaman',
          label: 'Peminjaman',
          group: 'Operasional',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          builder: (_) => const sp_borrow.SaprasBorrowingListPage(),
        ),
        NavItem(
          id: 'pengembalian',
          label: 'Pengembalian Unit',
          group: 'Operasional',
          icon: Icons.keyboard_return_rounded,
          selectedIcon: Icons.keyboard_return,
          builder: (_) => const sp_return.SaprasReturnListPage(),
        ),
        NavItem(
          id: 'inventaris',
          label: 'Inventaris Per Unit',
          group: 'Gudang',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          builder: (_) => const sp_inv.SaprasInventoryListPage(),
        ),
        NavItem(
          id: 'habis_pakai',
          label: 'Barang Habis Pakai',
          group: 'Gudang',
          icon: Icons.draw_outlined,
          selectedIcon: Icons.draw,
          builder: (_) => const sp_cons.SaprasConsumableListPage(),
        ),
        NavItem(
          id: 'perbaikan',
          label: 'Perbaikan (Repair)',
          group: 'Gudang',
          icon: Icons.build_outlined,
          selectedIcon: Icons.build,
          builder: (_) => const sp_repair.SaprasRepairListPage(),
        ),
        NavItem(
          id: 'notifikasi',
          label: 'Notifikasi Sapras',
          group: 'Akun',
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          builder: (_) => const sp_notif.SaprasNotificationPage(),
        ),
      ];

    case UserRole.admin:
      return [
        NavItem(
          id: 'dashboard',
          label: 'Dashboard Admin',
          group: 'Utama',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const adm_dash.AdminDashboardPage(),
        ),
        NavItem(
          id: 'users',
          label: 'Kelola User',
          group: 'Master Data',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          builder: (_) => const adm_users.AdminUserListPage(),
        ),
        NavItem(
          id: 'roles',
          label: 'Role Pengguna',
          group: 'Master Data',
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield,
          builder: (_) => const adm_roles.AdminRolePage(),
        ),
        NavItem(
          id: 'kategori',
          label: 'Kategori Barang',
          group: 'Master Data',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          builder: (_) => const adm_cat.AdminCategoryPage(),
        ),
        NavItem(
          id: 'model',
          label: 'Model / Jenis Barang',
          group: 'Master Data',
          icon: Icons.devices_other,
          selectedIcon: Icons.devices_other,
          builder: (_) => const adm_types.AdminItemTypePage(),
        ),
        NavItem(
          id: 'lokasi',
          label: 'Lokasi & Ruangan',
          group: 'Master Data',
          icon: Icons.place_outlined,
          selectedIcon: Icons.place,
          builder: (_) => const adm_loc.AdminLocationPage(),
        ),
        NavItem(
          id: 'audit',
          label: 'Audit Log Sistem',
          group: 'Sistem',
          icon: Icons.history,
          selectedIcon: Icons.history,
          builder: (_) => const adm_audit.AdminAuditLogPage(),
        ),
      ];
  }
}
